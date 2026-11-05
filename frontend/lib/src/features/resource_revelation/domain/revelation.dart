// Sensitive payloads are transient; diagnostics never include their values.
class RevelationFailure implements Exception {
  const RevelationFailure([this.statusCode]);
  final int? statusCode;
  @override
  String toString() =>
      'Não foi possível autorizar a visualização. Tente novamente ou confira sua solicitação.';
}

class RevelationRequest {
  const RevelationRequest(this.id, this.status, this.authorizedUntil);
  final String id, status;
  final DateTime? authorizedUntil;
  bool available(DateTime now) =>
      status == 'APROVADA' && (authorizedUntil?.isAfter(now) ?? false);
}

class RevelationResource {
  const RevelationResource({
    required this.organizationId,
    required this.teamId,
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.criticality,
    required this.maxViewSeconds,
    required this.allowsCodeCopy,
    required this.hasCredential,
    required this.hasTotp,
    required this.requests,
  });
  final String organizationId,
      teamId,
      id,
      name,
      description,
      category,
      criticality;
  final int maxViewSeconds;
  final bool allowsCodeCopy, hasCredential, hasTotp;
  final List<RevelationRequest> requests;
  String get criticalityLabel => switch (criticality) {
    'BAIXA' => 'Baixa',
    'MEDIA' => 'Média',
    'ALTA' => 'Alta',
    'CRITICA' => 'Crítica',
    _ => 'Protegido',
  };
}

class RevelationVerification {
  const RevelationVerification({
    this.proof,
    this.challengeToken,
    required this.requiresMfa,
  });
  final String? proof, challengeToken;
  final bool requiresMfa;
  @override
  String toString() => 'RevelationVerification[REDACTED]';
}

class RevelationSession {
  const RevelationSession({
    required this.id,
    required this.token,
    required this.expiresAt,
    required this.serverTime,
    required this.allowsCodeCopy,
    this.hasCredential = false,
    this.hasTotp = false,
  });
  final bool hasCredential, hasTotp;
  final String id, token;
  final DateTime expiresAt, serverTime;
  final bool allowsCodeCopy;
  @override
  String toString() => 'RevelationSession[REDACTED]';
}

class RevelationStatus {
  const RevelationStatus(this.serverTime, this.expiresAt, this.allowsCodeCopy);
  final DateTime serverTime, expiresAt;
  final bool allowsCodeCopy;
}

class RevelationValue {
  const RevelationValue({
    required this.kind,
    required this.serverTime,
    required this.expiresAt,
    required this.revealUntil,
    required this.allowsCodeCopy,
    this.login,
    this.password,
    this.additionalFields = const {},
    this.code,
    this.validUntil,
  });
  final String kind;
  final DateTime serverTime, expiresAt, revealUntil;
  final bool allowsCodeCopy;
  final String? login, password, code;
  final Map<String, String> additionalFields;
  final DateTime? validUntil;
  @override
  String toString() => 'RevelationValue[REDACTED]';
}

abstract class ResourceRevelationRepository {
  Object? get sessionIdentity;
  bool get hasValidSession;
  Future<List<RevelationResource>> catalog();
  Future<RevelationVerification> reauthenticate(String password);
  Future<RevelationVerification> verifyMfa(String challenge, String code);
  Future<RevelationSession> open(
    RevelationResource resource,
    String requestId,
    String proof,
  );
  Future<RevelationValue> reveal(
    RevelationResource resource,
    RevelationSession session,
    String kind, {
    bool copy = false,
  });
  Future<RevelationStatus> status(
    RevelationResource resource,
    RevelationSession session,
  );
  Future<void> close(RevelationResource resource, RevelationSession session);
  Future<void> requestAccess(
    RevelationResource resource,
    String justification,
    int seconds,
  );
}
