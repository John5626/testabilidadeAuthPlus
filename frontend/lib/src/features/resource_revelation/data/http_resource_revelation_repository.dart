import '../../../core/http/identity_api_client.dart';
import '../../studyapp/domain/auth_session_store.dart';
import '../domain/revelation.dart';

class HttpResourceRevelationRepository implements ResourceRevelationRepository {
  HttpResourceRevelationRepository({
    required this.client,
    required this.sessionStore,
  });
  final IdentityApiClient client;
  final AuthSessionStore sessionStore;
  @override
  Object? get sessionIdentity => sessionStore.session;
  @override
  bool get hasValidSession =>
      sessionStore.session?.expiresAt.isAfter(DateTime.now().toUtc()) ?? false;
  Future<Object?> _send(
    String method,
    String suffix, {
    String module = 'organizations',
    Object? body,
    Set<int> statuses = const {200},
  }) async {
    final session = sessionStore.session;
    if (session == null || !hasValidSession) throw const RevelationFailure(401);
    try {
      final value = await client.sendJson(
        method,
        suffix,
        module: module,
        body: body,
        headers: {
          'authorization': '${session.tokenType} ${session.accessToken}',
        },
        expectedStatuses: statuses,
      );
      if (!identical(session, sessionStore.session) || !hasValidSession) {
        throw const RevelationFailure(401);
      }
      return value;
    } on IdentityApiException catch (e) {
      if (e.statusCode == 401) sessionStore.clear();
      throw RevelationFailure(
        e.statusCode,
      ); // No provider messages/body copied to logs/state/UI.
    } on RevelationFailure {
      rethrow;
    } catch (_) {
      throw const RevelationFailure();
    }
  }

  String _base(RevelationResource r) =>
      '${r.organizationId}/teams/${r.teamId}/resources/${r.id}/revelation-sessions';
  @override
  Future<List<RevelationResource>> catalog() async {
    final value = await _send('GET', '', module: 'resource-revelations');
    if (value is! List) throw const RevelationFailure();
    return value
        .map((v) {
          final m = _map(v);
          final requests = (m['requests'] as List? ?? [])
              .map((v) {
                final q = _map(v);
                return RevelationRequest(
                  _s(q, 'requestId'),
                  _s(q, 'status'),
                  DateTime.tryParse(q['authorizedUntil'] as String? ?? ''),
                );
              })
              .toList(growable: false);
          return RevelationResource(
            organizationId: _s(m, 'organizationId'),
            teamId: _s(m, 'teamId'),
            id: _s(m, 'resourceId'),
            name: _s(m, 'name'),
            description: m['description'] as String? ?? '',
            category: m['category'] as String? ?? '',
            criticality: _s(m, 'criticality'),
            maxViewSeconds: m['maxViewSeconds'] as int,
            allowsCodeCopy: m['allowsCodeCopy'] == true,
            hasCredential: m['hasCredential'] == true,
            hasTotp: m['hasTotp'] == true,
            requests: requests,
          );
        })
        .toList(growable: false);
  }

  RevelationVerification _verification(Object? v) {
    final m = _map(v);
    return RevelationVerification(
      proof: m['proof'] as String?,
      challengeToken: m['challengeToken'] as String?,
      requiresMfa: m['requiresMfa'] == true,
    );
  }

  @override
  Future<RevelationVerification> reauthenticate(String password) async =>
      _verification(
        await _send(
          'POST',
          'resource-reauthentication',
          module: 'identity',
          body: {'password': password},
        ),
      );
  @override
  Future<RevelationVerification> verifyMfa(
    String challenge,
    String code,
  ) async => _verification(
    await _send(
      'POST',
      'resource-reauthentication/mfa',
      module: 'identity',
      body: {'challengeToken': challenge, 'code': code},
    ),
  );
  @override
  Future<RevelationSession> open(
    RevelationResource r,
    String requestId,
    String proof,
  ) async {
    final m = _map(
      await _send(
        'POST',
        _base(r),
        body: {'requestId': requestId, 'reauthenticationProof': proof},
        statuses: const {201},
      ),
    );
    return RevelationSession(
      id: _s(m, 'sessionId'),
      hasCredential: m['hasCredential'] == true,
      hasTotp: m['hasTotp'] == true,
      token: _s(m, 'sessionToken'),
      expiresAt: _date(m, 'expiresAt'),
      serverTime: _date(m, 'serverTime'),
      allowsCodeCopy: m['allowsCodeCopy'] == true,
    );
  }

  @override
  Future<RevelationValue> reveal(
    RevelationResource r,
    RevelationSession session,
    String kind, {
    bool copy = false,
  }) async {
    final m = _map(
      await _send(
        'POST',
        '${_base(r)}/${session.id}/${copy ? 'copy-totp' : 'reveal'}',
        body: {'sessionToken': session.token, if (!copy) 'kind': kind},
      ),
    );
    final c = m['credential'] == null ? null : _map(m['credential']);
    final t = m['totp'] == null ? null : _map(m['totp']);
    final extras = c?['additionalFields'];
    return RevelationValue(
      kind: _s(m, 'kind'),
      serverTime: _date(m, 'serverTime'),
      expiresAt: _date(m, 'expiresAt'),
      revealUntil: _date(m, 'revealUntil'),
      allowsCodeCopy: m['allowsCodeCopy'] == true,
      login: c?['login'] as String?,
      password: c?['password'] as String?,
      additionalFields: extras is Map
          ? extras.map((k, v) => MapEntry(k as String, v as String))
          : const {},
      code: t?['code'] as String?,
      validUntil: t == null ? null : _date(t, 'validUntil'),
    );
  }

  @override
  Future<RevelationStatus> status(
    RevelationResource r,
    RevelationSession session,
  ) async {
    final m = _map(
      await _send(
        'POST',
        '${_base(r)}/${session.id}/status',
        body: {'sessionToken': session.token},
      ),
    );
    if (m['active'] != true) throw const RevelationFailure(403);
    return RevelationStatus(
      _date(m, 'serverTime'),
      _date(m, 'expiresAt'),
      m['allowsCodeCopy'] == true,
    );
  }

  @override
  Future<void> close(RevelationResource r, RevelationSession s) async {
    await _send(
      'POST',
      '${_base(r)}/${s.id}/close',
      body: {'sessionToken': s.token},
      statuses: const {204},
    );
  }

  @override
  Future<void> requestAccess(
    RevelationResource r,
    String justification,
    int seconds,
  ) async {
    await _send(
      'POST',
      '${r.organizationId}/teams/${r.teamId}/resources/${r.id}/access-requests',
      body: {
        'type': 'VISUALIZACAO_CONTROLADA',
        'durationSeconds': seconds,
        'justification': justification,
      },
      statuses: const {201},
    );
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const RevelationFailure();
  }

  String _s(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v is String) return v;
    throw const RevelationFailure();
  }

  DateTime _date(Map<String, dynamic> m, String k) {
    final v = DateTime.tryParse(_s(m, k));
    if (v != null) return v.toUtc();
    throw const RevelationFailure();
  }
}
