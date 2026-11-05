import '../../resource_revelation/domain/revelation.dart';
import '../../resource_revelation/data/http_resource_revelation_repository.dart';
import 'dart:convert';

import '../../../core/config/app_config.dart';
import '../../../core/http/identity_api_client.dart';
import '../domain/auth_session_store.dart';
import '../domain/studyapp_models.dart';
import '../domain/studyapp_repository.dart';
import '../domain/authentication.dart';
import 'mock_studyapp_repository.dart';

class IdentityStudyAppRepository implements StudyAppRepository {
  IdentityStudyAppRepository({
    required AppConfig config,
    required this.sessionStore,
    IdentityApiClient? client,
    MockStudyAppRepository? demoRepository,
  }) : _client = client ?? IdentityApiClient(config: config),
       _demo = demoRepository ?? MockStudyAppRepository();

  final AuthSessionStore sessionStore;
  final IdentityApiClient _client;
  final MockStudyAppRepository _demo;
  final List<TeamInvitationSummary> _invitationSummaries = [];

  late final ResourceRevelationRepository _resourceRevelation =
      HttpResourceRevelationRepository(
        client: _client,
        sessionStore: sessionStore,
      );
  @override
  ResourceRevelationRepository? get revelation =>
      sessionStore.session == null ? null : _resourceRevelation;

  String? _organizationId;

  Map<String, String> get _authorizationHeaders {
    final session = sessionStore.session;
    if (session == null || !session.expiresAt.isAfter(DateTime.now().toUtc())) {
      throw const IdentityWorkspaceException(
        'Sua sessão expirou. Faça login novamente.',
      );
    }
    return {'authorization': '${session.tokenType} ${session.accessToken}'};
  }

  @override
  Future<WorkspaceData> loadWorkspace() async {
    if (sessionStore.session == null) {
      return _demo.loadWorkspace();
    }
    final demo = await _demo.loadWorkspace();
    final Object? sessionJson;
    try {
      sessionJson = await _authorizedJson('GET', 'session');
    } on IdentityApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        sessionStore.clear();
        throw const IdentitySessionInvalidException();
      }
      rethrow;
    }
    final session = _SessionContext.fromJson(_object(sessionJson));
    _organizationId = session.organizationIds.firstOrNull;

    final organizationId = _organizationId;
    final teams = organizationId == null
        ? const <OrganizationTeam>[]
        : await _loadTeams(organizationId);
    final users = organizationId == null
        ? const <OrganizationMember>[]
        : await _loadUsers(organizationId);
    final audits = organizationId == null
        ? const <AuditEvent>[]
        : await _loadAuditEvents(organizationId);
    final primaryTeam = teams
        .where((team) => team.id == session.teamIds.firstOrNull)
        .firstOrNull;
    var realResourceFeatures = session.permissions.contains(
      'USE_TEAM_RESOURCES',
    );
    var catalog = const <RevelationResource>[];
    if (realResourceFeatures) {
      try {
        catalog = await _resourceRevelation.catalog();
      } on RevelationFailure catch (error) {
        if (error.statusCode == 401) {
          sessionStore.clear();
          throw const IdentitySessionInvalidException();
        }
        if (error.statusCode == 404 || error.statusCode == 403) {
          realResourceFeatures = false;
        } else {
          rethrow;
        }
      }
    }
    final resources = catalog
        .map(
          (item) => ProtectedResource(
            id: item.id,
            name: item.name,
            description: item.description,
            team:
                teams.where((t) => t.id == item.teamId).firstOrNull?.name ??
                'Equipe vinculada',
            category: item.category,
            risk: item.criticality == 'CRITICA'
                ? ResourceRisk.critical
                : ResourceRisk.moderate,
            provisioning: 'Gerenciado',
            vaultLabel: 'Cofre protegido',
            lastAccessLabel: 'Visualização controlada',
            iconLabel: item.name.isEmpty
                ? 'R'
                : item.name.substring(0, 1).toUpperCase(),
            revelationResource: item,
          ),
        )
        .toList(growable: false);
    final profile = UserProfile(
      fullName: session.displayName,
      email: session.email,
      organization: organizationId ?? 'Escopo de sistema',
      team: primaryTeam?.name ?? 'Sem equipe ativa',
      role: session.profiles.isEmpty
          ? 'Usuário'
          : session.profiles.map(_profileLabel).join(' • '),
      phone: '',
      twoFactorEnabled: false,
      vaultType: VaultType.studyApp,
      canInviteTeamUsers:
          session.permissions.contains('MANAGE_ORGANIZATION_USERS') ||
          session.permissions.contains('MANAGE_TEAM_USERS'),
      canManageTeams: session.permissions.contains('MANAGE_ORGANIZATION_TEAMS'),
      canManagePolicies: session.permissions.contains(
        'MANAGE_INSTITUTIONAL_POLICIES',
      ),
      canAudit: session.permissions.contains('VIEW_AUDIT_EVENTS'),
      resourceFeaturesAvailable: realResourceFeatures,
      canApproveRequests: session.permissions.contains('APPROVE_TEAM_REQUESTS'),
      canUseResources: session.permissions.contains('USE_TEAM_RESOURCES'),
    );
    final pendingUsers = users
        .where((user) => user.status == TeamMemberStatus.pending)
        .length;

    return WorkspaceData(
      dashboard: DashboardData(
        userName: session.firstName,
        resourceCount: resources.length,
        activeDelegations: users
            .where((user) => user.status == TeamMemberStatus.active)
            .length,
        pendingRequests:
            catalog.fold(
              0,
              (sum, item) =>
                  sum +
                  item.requests.where((r) => r.status == 'PENDENTE').length,
            ) +
            pendingUsers,
        alertCount: audits
            .where((event) => event.severity == AuditSeverity.alert)
            .length,
        recentEvents: audits.take(3).toList(growable: false),
      ),
      resources: resources,
      auditEvents: audits,
      pendingRequest: demo.pendingRequest,
      profile: profile,
      teams: teams,
      members: users,
      invitations: List.unmodifiable(_invitationSummaries),
    );
  }

  Future<List<OrganizationTeam>> _loadTeams(String organizationId) async {
    try {
      final response = await _authorizedJson(
        'GET',
        'organizations/$organizationId/teams',
      );
      return _list(
        response,
      ).map((item) => _team(_object(item))).toList(growable: false);
    } on IdentityApiException catch (error) {
      if (error.statusCode == 403) return const [];
      rethrow;
    }
  }

  Future<List<OrganizationMember>> _loadUsers(String organizationId) async {
    try {
      final response = await _authorizedJson(
        'GET',
        'organizations/$organizationId/users',
      );
      return _list(
        response,
      ).map((item) => _member(_object(item))).toList(growable: false);
    } on IdentityApiException catch (error) {
      if (error.statusCode == 403) return const [];
      rethrow;
    }
  }

  Future<List<AuditEvent>> _loadAuditEvents(String organizationId) async {
    try {
      final response = await _withSessionCheck(
        () => _client.sendJson(
          'GET',
          'organizations/$organizationId/events',
          module: 'audit',
          headers: _authorizationHeaders,
          queryParameters: const {'page': '0', 'size': '50'},
        ),
      );
      final page = _object(response);
      return _list(
        page['items'],
      ).map((item) => _auditEvent(_object(item))).toList(growable: false);
    } on IdentityApiException catch (error) {
      if (error.statusCode == 403) return const [];
      rethrow;
    }
  }

  @override
  Future<TeamInvitationReceipt> inviteTeamUser(
    InviteTeamUserInput input,
  ) async {
    final organizationId = _requireOrganizationId();
    final response = await _authorizedJson(
      'POST',
      'organizations/$organizationId/users',
      body: {
        'teamId': input.teamId,
        'email': input.email.trim(),
        'firstName': input.firstName.trim(),
        if (input.lastName?.trim().isNotEmpty ?? false)
          'lastName': input.lastName!.trim(),
        'teamRole': _teamRoleApiValue(input.teamRole),
        'profiles': input.profiles
            .map(_profileApiValue)
            .toList(growable: false),
      },
      expectedStatuses: const {201},
    );
    final json = _object(response);
    final invitationJson = _object(json['invitation']);
    final member = _member(json);
    final summary = TeamInvitationSummary(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      email: json['email'] as String,
      expiresAt: DateTime.parse(invitationJson['expiresAt'] as String),
      status: 'PENDENTE',
    );
    _invitationSummaries.removeWhere((item) => item.id == summary.id);
    _invitationSummaries.insert(0, summary);
    return TeamInvitationReceipt(
      invitation: summary,
      member: member,
      oneTimeToken: invitationJson['token'] as String,
    );
  }

  @override
  Future<TeamInvitationPreview> validateTeamInvitation(String token) async {
    final response = await _client.sendJson(
      'POST',
      'invitations/preview',
      body: {'token': token.trim()},
    );
    final json = _object(response);
    return TeamInvitationPreview(
      invitationId: json['invitationId'] as String,
      fullName: json['displayName'] as String,
      email: json['email'] as String,
      organizationName: json['organizationName'] as String? ?? 'Organização',
      teamName: json['teamName'] as String,
      teamRole: json['teamRole'] as String,
      profiles: _list(json['profiles']).cast<String>().toSet(),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      accountExists: json['accountExists'] as bool? ?? false,
      requiresTermsAcceptance: json['requiresTermsAcceptance'] as bool,
      policies: _list(
        json['policies'],
      ).map((item) => _requiredPolicy(_object(item))).toList(growable: false),
    );
  }

  @override
  Future<TeamInvitationAcceptance> acceptTeamInvitation(
    AcceptTeamInvitationInput input,
  ) async {
    final response = await _client.sendJson(
      'POST',
      'invitations/complete',
      body: {
        'token': input.token.trim(),
        if (input.password.isNotEmpty) 'password': input.password,
        if (input.passwordConfirmation.isNotEmpty)
          'passwordConfirmation': input.passwordConfirmation,
        'personalDataConsentAccepted': input.personalDataConsentAccepted,
        'policyVersionIds': input.policyVersionIds.toList(growable: false),
      },
    );
    final json = _object(response);
    final user = _object(json['user']);
    final authentication = json['authentication'] == null
        ? null
        : _authenticatedSession(_object(json['authentication']));
    if (authentication != null) sessionStore.startSession(authentication);
    return TeamInvitationAcceptance(
      email: user['email'] as String,
      teamName: user['teamName'] as String,
      accountCreated: json['accountCreated'] as bool,
      requiresFirstAccess: false,
      session: authentication,
    );
  }

  @override
  Future<OrganizationTeam> saveTeam(SaveOrganizationTeamInput input) async {
    final organizationId = _requireOrganizationId();
    final creating = input.teamId == null;
    final response = await _authorizedJson(
      creating ? 'POST' : 'PUT',
      creating
          ? 'organizations/$organizationId/teams'
          : 'organizations/$organizationId/teams/${input.teamId}',
      body: {
        'name': input.name.trim(),
        if (input.acronym?.trim().isNotEmpty ?? false)
          'acronym': input.acronym!.trim(),
        'description': input.description.trim(),
        'responsibleUserId': input.responsibleUserId,
      },
      expectedStatuses: creating ? const {201} : const {200},
    );
    return _team(_object(response));
  }

  @override
  Future<void> setTeamStatus({
    required String teamId,
    required TeamStatus status,
  }) async {
    final organizationId = _requireOrganizationId();
    await _authorizedJson(
      'PATCH',
      'organizations/$organizationId/teams/$teamId/status',
      body: {'status': status == TeamStatus.active ? 'ACTIVE' : 'INACTIVE'},
    );
  }

  @override
  Future<OrganizationMember> updateTeamUser(
    UpdateOrganizationMemberInput input,
  ) async {
    final organizationId = _requireOrganizationId();
    final response = await _authorizedJson(
      'PUT',
      'organizations/$organizationId/users/${input.userId}',
      body: {
        'teamId': input.teamId,
        'firstName': input.firstName.trim(),
        if (input.lastName?.trim().isNotEmpty ?? false)
          'lastName': input.lastName!.trim(),
        'teamRole': _teamRoleApiValue(input.teamRole),
        'profiles': input.profiles
            .map(_profileApiValue)
            .toList(growable: false),
      },
    );
    return _member(_object(response));
  }

  @override
  Future<void> setTeamUserStatus({
    required String userId,
    required String teamId,
    required TeamMemberStatus status,
  }) async {
    final organizationId = _requireOrganizationId();
    final apiStatus = switch (status) {
      TeamMemberStatus.active => 'ACTIVE',
      TeamMemberStatus.pending => 'PENDING',
      TeamMemberStatus.blocked => 'BLOCKED',
      TeamMemberStatus.inactive => 'DISABLED',
    };
    await _authorizedJson(
      'PATCH',
      'organizations/$organizationId/users/$userId/status',
      body: {'status': apiStatus, 'teamId': teamId},
    );
  }

  @override
  Future<void> disableTeamUser(String userId) async {
    final organizationId = _requireOrganizationId();
    await _authorizedJson(
      'DELETE',
      'organizations/$organizationId/users/$userId',
      expectedStatuses: const {204},
    );
  }

  @override
  Future<String> exportAuditCsv() {
    final organizationId = _requireOrganizationId();
    return _withSessionCheck(
      () => _client.sendText(
        'GET',
        'organizations/$organizationId/events/export',
        module: 'audit',
        headers: _authorizationHeaders,
        queryParameters: const {'format': 'CSV'},
      ),
    );
  }

  @override
  Future<List<InstitutionalPolicy>> listInstitutionalPolicies() async {
    final response = await _authorizedJson('GET', 'admin/policies');
    return _list(
      response,
    ).map((item) => _policy(_object(item))).toList(growable: false);
  }

  @override
  Future<InstitutionalPolicy> createInstitutionalPolicy(
    SaveInstitutionalPolicyInput input,
  ) async {
    final response = await _authorizedJson(
      'POST',
      'admin/policies',
      body: {
        'code': input.code.trim().toUpperCase(),
        'title': input.title.trim(),
        'type': input.type.trim(),
        'version': input.version.trim(),
        'content': input.content,
        'required': input.required,
        'effectiveAt': input.effectiveAt.toUtc().toIso8601String(),
      },
      expectedStatuses: const {201},
    );
    return _policy(_object(response));
  }

  @override
  Future<InstitutionalPolicy> updateInstitutionalPolicy({
    required String policyId,
    required String title,
    required String type,
  }) async {
    final response = await _authorizedJson(
      'PUT',
      'admin/policies/$policyId',
      body: {'title': title.trim(), 'type': type.trim()},
    );
    return _policy(_object(response));
  }

  @override
  Future<void> deactivateInstitutionalPolicy(String policyId) async {
    await _authorizedJson(
      'DELETE',
      'admin/policies/$policyId',
      expectedStatuses: const {204},
    );
  }

  @override
  Future<InstitutionalPolicyVersion> createInstitutionalPolicyVersion({
    required String policyId,
    required String version,
    required String content,
    required bool required,
    required DateTime effectiveAt,
  }) async {
    final response = await _authorizedJson(
      'POST',
      'admin/policies/$policyId/versions',
      body: {
        'version': version.trim(),
        'content': content,
        'required': required,
        'effectiveAt': effectiveAt.toUtc().toIso8601String(),
      },
      expectedStatuses: const {201},
    );
    return _policyVersion(_object(response));
  }

  @override
  Future<InstitutionalPolicyVersion> publishInstitutionalPolicyVersion({
    required String policyId,
    required String versionId,
  }) async {
    final response = await _authorizedJson(
      'POST',
      'admin/policies/$policyId/versions/$versionId/publication',
    );
    return _policyVersion(_object(response));
  }

  Future<Object?> _authorizedJson(
    String method,
    String suffix, {
    Object? body,
    Set<int> expectedStatuses = const {200},
  }) => suffix == 'session'
      ? _client.sendJson(
          method,
          suffix,
          headers: _authorizationHeaders,
          body: body,
          expectedStatuses: expectedStatuses,
        )
      : _withSessionCheck(
          () => _client.sendJson(
            method,
            suffix,
            headers: _authorizationHeaders,
            body: body,
            expectedStatuses: expectedStatuses,
          ),
        );

  Future<T> _withSessionCheck<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on IdentityApiException catch (error) {
      if (error.statusCode != 401 && error.statusCode != 403) rethrow;
      try {
        await _client.sendJson(
          'GET',
          'session',
          headers: _authorizationHeaders,
        );
      } on IdentityApiException catch (sessionError) {
        if (sessionError.statusCode == 401 || sessionError.statusCode == 403) {
          sessionStore.clear();
          throw const IdentitySessionInvalidException();
        }
      }
      rethrow;
    }
  }

  String _requireOrganizationId() {
    final value = _organizationId;
    if (value == null) {
      throw const IdentityWorkspaceException(
        'Nenhuma organização ativa foi encontrada para esta sessão.',
      );
    }
    return value;
  }

  OrganizationTeam _team(Map<String, dynamic> json) => OrganizationTeam(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    adminName: json['responsibleDisplayName'] as String? ?? 'Sem responsável',
    memberCount: (json['memberCount'] as num).toInt(),
    status: json['status'] == 'ACTIVE'
        ? TeamStatus.active
        : TeamStatus.inactive,
    createdAt: DateTime.parse(json['createdAt'] as String),
    acronym: json['acronym'] as String?,
    responsibleUserId: json['responsibleUserId'] as String?,
  );

  OrganizationMember _member(Map<String, dynamic> json) => OrganizationMember(
    id: json['id'] as String,
    teamId: json['teamId'] as String,
    fullName: json['displayName'] as String,
    email: json['email'] as String,
    teamRole: json['teamRole'] as String,
    profileLabel: _list(json['profiles']).cast<String>().join(' • '),
    status: switch (json['membershipStatus'] ?? json['status']) {
      'ACTIVE' => TeamMemberStatus.active,
      'BLOCKED' => TeamMemberStatus.blocked,
      'INACTIVE' || 'DISABLED' => TeamMemberStatus.inactive,
      _ => TeamMemberStatus.pending,
    },
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String?,
    profiles: _list(json['profiles']).cast<String>().toSet(),
    termsAcceptanceRequired: json['termsAcceptanceRequired'] as bool? ?? false,
  );

  InstitutionalPolicy _policy(Map<String, dynamic> json) => InstitutionalPolicy(
    id: json['id'] as String,
    code: json['code'] as String,
    title: json['title'] as String,
    type: json['type'] as String,
    status: json['status'] as String,
    versions: _list(
      json['versions'],
    ).map((item) => _policyVersion(_object(item))).toList(growable: false),
  );

  InstitutionalPolicyVersion _policyVersion(Map<String, dynamic> json) =>
      InstitutionalPolicyVersion(
        id: json['id'] as String,
        version: json['version'] as String,
        content: json['content'] as String,
        required: json['required'] as bool,
        status: json['status'] as String,
        effectiveAt: DateTime.parse(json['effectiveAt'] as String),
        publishedAt: json['publishedAt'] == null
            ? null
            : DateTime.parse(json['publishedAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  AuditEvent _auditEvent(Map<String, dynamic> json) {
    final severity = (json['severity'] as String).toUpperCase();
    final occurredAt = DateTime.parse(json['occurredAt'] as String).toLocal();
    return AuditEvent(
      id: json['id'] as String,
      title: json['eventType'] as String,
      subtitle: json['description'] as String? ?? json['result'] as String,
      timeLabel:
          '${occurredAt.hour.toString().padLeft(2, '0')}:${occurredAt.minute.toString().padLeft(2, '0')}',
      severity: severity == 'CRITICAL' || severity == 'ALERT'
          ? AuditSeverity.alert
          : severity == 'INFO'
          ? AuditSeverity.info
          : AuditSeverity.operation,
      iconCode: 'audit',
    );
  }

  RequiredPolicy _requiredPolicy(Map<String, dynamic> json) => RequiredPolicy(
    policyVersionId: json['policyVersionId'] as String,
    policyCode: json['policyCode'] as String,
    title: json['title'] as String,
    type: json['type'] as String,
    version: json['version'] as String,
    content: json['content'] as String,
    contentFormat: json['contentFormat'] as String,
    contentHash: json['contentHash'] as String,
    effectiveAt: DateTime.parse(json['effectiveAt'] as String),
    publishedAt: DateTime.parse(json['publishedAt'] as String),
  );

  AuthenticatedSession _authenticatedSession(Map<String, dynamic> json) {
    final accessToken = json['accessToken'] as String;
    final tokenType = json['tokenType'] as String;
    if (tokenType.toLowerCase() != 'bearer' ||
        !_hasJwtPurpose(
          accessToken,
          tokenUse: 'ACCESS',
          audience: 'studyapp-api',
        )) {
      throw const IdentityWorkspaceException(
        'A API retornou uma sessão de autenticação inválida.',
      );
    }
    return AuthenticatedSession(
      accessToken: accessToken,
      tokenType: tokenType,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  bool _hasJwtPurpose(
    String token, {
    required String tokenUse,
    required String audience,
  }) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic> ||
          payload['token_use'] != tokenUse) {
        return false;
      }
      final claim = payload['aud'];
      return claim == audience ||
          (claim is List<dynamic> && claim.contains(audience));
    } on FormatException {
      return false;
    }
  }

  String _profileLabel(String profile) => profile
      .toLowerCase()
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  String _teamRoleApiValue(String role) => switch (role.trim()) {
    'Membro' => 'MEMBRO',
    'Responsável' => 'RESPONSAVEL',
    'Aprovador de Recursos' => 'APROVADOR',
    final value => value.toUpperCase(),
  };

  String _profileApiValue(String profile) => switch (profile.trim()) {
    'Membro equipe' => 'MEMBRO_EQUIPE',
    'Aprovador equipe' => 'APROVADOR_EQUIPE',
    'Admin equipe' => 'ADMIN_EQUIPE',
    'Admin organização' => 'ADMIN_ORGANIZACAO',
    'Admin sistema' => 'ADMIN_SISTEMA',
    'Auditor' => 'AUDITOR',
    final value => value.toUpperCase(),
  };

  List<dynamic> _list(Object? value) {
    if (value is List<dynamic>) return value;
    throw const IdentityWorkspaceException('Resposta inválida da API.');
  }

  Map<String, dynamic> _object(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const IdentityWorkspaceException('Resposta inválida da API.');
  }

  @override
  Future<void> completeFirstAccess(FirstAccessSetup setup) =>
      _demo.completeFirstAccess(setup);

  @override
  Future<ProtectedResource> createResource({
    required String name,
    required String description,
    required String category,
    required ResourceRisk risk,
    required String provisioning,
  }) {
    if (sessionStore.session != null) {
      throw const IdentityWorkspaceException(
        'Cadastro de recurso indisponível neste fluxo.',
      );
    }
    return _demo.createResource(
      name: name,
      description: description,
      category: category,
      risk: risk,
      provisioning: provisioning,
    );
  }

  @override
  Future<AccessRequest> requestAccess({
    required ProtectedResource resource,
    required String justification,
    required String accessType,
    required int durationMinutes,
    required String priority,
  }) {
    if (sessionStore.session != null) {
      throw const IdentityWorkspaceException(
        'Use a solicitação de acesso do recurso autorizado.',
      );
    }
    return _demo.requestAccess(
      resource: resource,
      justification: justification,
      accessType: accessType,
      durationMinutes: durationMinutes,
      priority: priority,
    );
  }

  @override
  Future<void> decideRequest({
    required String requestId,
    required bool approve,
  }) {
    if (sessionStore.session != null) {
      throw const IdentityWorkspaceException(
        'Decisão de acesso indisponível neste fluxo.',
      );
    }
    return _demo.decideRequest(requestId: requestId, approve: approve);
  }
}

class _SessionContext {
  const _SessionContext({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.displayName,
    required this.profiles,
    required this.permissions,
    required this.organizationIds,
    required this.teamIds,
  });

  factory _SessionContext.fromJson(Map<String, dynamic> json) {
    final organizations = (json['organizations'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return _SessionContext(
      userId: json['userId'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      displayName: json['displayName'] as String,
      profiles: (json['profiles'] as List<dynamic>? ?? const [])
          .cast<String>()
          .toSet(),
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .cast<String>()
          .toSet(),
      organizationIds: organizations
          .map((item) => item['organizationId'] as String)
          .toList(growable: false),
      teamIds: organizations
          .expand((item) => (item['teamIds'] as List<dynamic>).cast<String>())
          .toList(growable: false),
    );
  }

  final String userId;
  final String email;
  final String firstName;
  final String displayName;
  final Set<String> profiles;
  final Set<String> permissions;
  final List<String> organizationIds;
  final List<String> teamIds;
}

class IdentityWorkspaceException implements Exception {
  const IdentityWorkspaceException(this.message);
  final String message;

  @override
  String toString() => message;
}
