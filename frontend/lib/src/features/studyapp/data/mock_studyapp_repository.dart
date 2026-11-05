import '../domain/studyapp_models.dart';
import '../domain/studyapp_repository.dart';

class MockStudyAppRepository extends StudyAppRepository {
  FirstAccessSetup? _firstAccess;
  final List<ProtectedResource> _resources = [..._initialResources];
  final List<AuditEvent> _events = [..._initialEvents];
  final List<OrganizationTeam> _teams = [..._initialTeams];
  final List<OrganizationMember> _members = [..._initialMembers];
  final List<TeamInvitationSummary> _invitations = [..._initialInvitations];
  final Map<String, String> _invitationTokens = {
    'studyapp-demo-carlos': 'invite-carlos',
    'studyapp-demo-marina': 'invite-marina',
  };
  final Map<String, TeamInvitationPreview> _invitationPreviews = {
    for (final preview in _initialInvitationPreviews)
      preview.invitationId: preview,
  };
  final Set<String> _existingAccountEmails = {
    'fixture-002818759c@example.invalid',
  };

  @override
  Future<void> completeFirstAccess(FirstAccessSetup setup) async {
    await _latency();
    _firstAccess = setup;
  }

  @override
  Future<WorkspaceData> loadWorkspace() async {
    await _latency();
    final setup = _firstAccess;
    final profile = UserProfile(
      fullName: 'Pessoa Exemplo',
      email: 'fixture-8379c1e907@example.invalid',
      organization: 'EXAMPLE-MG',
      team: 'Tecnologia da Informação',
      role: setup?.jobTitle ?? 'Administrador de TI',
      phone: setup?.phone ?? '(31) 98765-4321',
      twoFactorEnabled: setup?.twoFactorEnabled ?? true,
      vaultType: setup?.vaultType ?? VaultType.studyApp,
      canInviteTeamUsers: true,
      canManageTeams: true,
      canManagePolicies: true,
      canAudit: true,
    );

    final pending = AccessRequest(
      id: 'request-001',
      resource: _resources.first,
      requester: profile.fullName,
      justification:
          'Necessário para manutenção do ambiente de produção e validação de credenciais.',
      accessType: 'Visualização controlada do acesso',
      durationMinutes: 30,
      priority: 'Alta',
      requestedAt: DateTime.now(),
    );

    return WorkspaceData(
      dashboard: DashboardData(
        userName: profile.fullName.split(' ').first,
        resourceCount: _resources.length,
        activeDelegations: 6,
        pendingRequests: 3,
        alertCount: 2,
        recentEvents: _events.take(3).toList(),
      ),
      resources: List.unmodifiable(_resources),
      auditEvents: List.unmodifiable(_events),
      pendingRequest: pending,
      profile: profile,
      teams: List.unmodifiable(_teams),
      members: List.unmodifiable(_members),
      invitations: List.unmodifiable(_invitations),
    );
  }

  @override
  Future<TeamInvitationReceipt> inviteTeamUser(
    InviteTeamUserInput input,
  ) async {
    await _latency();
    final emailAlreadyUsed = _members.any(
      (member) => member.email.toLowerCase() == input.email.toLowerCase(),
    );
    if (emailAlreadyUsed) {
      throw const MockRepositoryException(
        'Já existe um usuário com este e-mail na organização.',
      );
    }

    final sequence = _members.length + 1;
    final fullName = [
      input.firstName.trim(),
      if (input.lastName?.trim().isNotEmpty ?? false) input.lastName!.trim(),
    ].join(' ');
    final member = OrganizationMember(
      id: 'member-$sequence',
      teamId: input.teamId,
      fullName: fullName,
      email: input.email,
      teamRole: input.teamRole,
      profileLabel: input.profiles.join(' • '),
      status: TeamMemberStatus.pending,
      firstName: input.firstName,
      lastName: input.lastName,
      profiles: input.profiles,
    );
    final invitation = TeamInvitationSummary(
      id: 'invite-$sequence',
      teamId: input.teamId,
      email: input.email,
      expiresAt: DateTime.now().add(const Duration(hours: 72)),
      status: 'PENDENTE',
    );
    _members.insert(0, member);
    _invitations.insert(0, invitation);
    _updateTeamMemberCount(input.teamId, 1);
    _events.insert(
      0,
      AuditEvent(
        id: 'evt-${_events.length + 1}',
        title: 'Convite de usuário criado',
        subtitle: 'Equipe: ${_teamName(input.teamId)} • usuário convidado',
        timeLabel: 'Agora',
        severity: AuditSeverity.operation,
        iconCode: 'invite',
      ),
    );

    final token = 'studyapp-invite-${DateTime.now().millisecondsSinceEpoch}';
    _invitationTokens[token] = invitation.id;
    _invitationPreviews[invitation.id] = TeamInvitationPreview(
      invitationId: invitation.id,
      fullName: fullName,
      email: input.email,
      organizationName: 'EXAMPLE-MG',
      teamName: _teamName(input.teamId),
      teamRole: input.teamRole,
      profiles: Set.unmodifiable(input.profiles),
      expiresAt: invitation.expiresAt,
      accountExists: false,
      requiresTermsAcceptance: true,
    );

    return TeamInvitationReceipt(
      invitation: invitation,
      member: member,
      oneTimeToken: token,
    );
  }

  @override
  Future<TeamInvitationPreview> validateTeamInvitation(String token) async {
    await _latency();
    return _resolveInvitation(token);
  }

  @override
  Future<TeamInvitationAcceptance> acceptTeamInvitation(
    AcceptTeamInvitationInput input,
  ) async {
    await _latency();
    final preview = _resolveInvitation(input.token);
    final password = input.password;
    if (!preview.accountExists &&
        (password.runes.length < 12 || password.runes.length > 128)) {
      throw const MockRepositoryException(
        'Não foi possível aceitar o convite. Revise os dados e tente novamente.',
      );
    }
    if (!preview.accountExists && !input.personalDataConsentAccepted) {
      throw const MockRepositoryException(
        'Confirme o tratamento de dados para aceitar o convite.',
      );
    }
    if (!preview.accountExists && input.passwordConfirmation != password) {
      throw const MockRepositoryException(
        'Não foi possível aceitar o convite. Revise os dados e tente novamente.',
      );
    }

    final invitationIndex = _invitations.indexWhere(
      (invitation) => invitation.id == preview.invitationId,
    );
    _invitations[invitationIndex] = _invitations[invitationIndex].copyWith(
      status: 'USADO',
    );
    final memberIndex = _members.indexWhere(
      (member) =>
          member.email.toLowerCase() == preview.email.toLowerCase() &&
          member.teamId == _invitations[invitationIndex].teamId,
    );
    if (memberIndex != -1) {
      _members[memberIndex] = _members[memberIndex].copyWith(
        status: TeamMemberStatus.active,
      );
    }

    final accountCreated = !_existingAccountEmails.contains(
      preview.email.toLowerCase(),
    );
    _existingAccountEmails.add(preview.email.toLowerCase());
    _invitationTokens.remove(input.token.trim());
    _events.insert(
      0,
      AuditEvent(
        id: 'evt-${_events.length + 1}',
        title: 'Convite de usuário concluído',
        subtitle: 'Equipe: ${preview.teamName} • vínculo confirmado',
        timeLabel: 'Agora',
        severity: AuditSeverity.operation,
        iconCode: 'invite-accepted',
      ),
    );

    return TeamInvitationAcceptance(
      email: preview.email,
      teamName: preview.teamName,
      accountCreated: accountCreated,
      requiresFirstAccess: accountCreated,
    );
  }

  TeamInvitationPreview _resolveInvitation(String rawToken) {
    final invitationId = _invitationTokens[rawToken.trim()];
    final invitationIndex = _invitations.indexWhere(
      (invitation) => invitation.id == invitationId,
    );
    if (invitationId == null || invitationIndex == -1) {
      throw const MockRepositoryException(
        'Não foi possível validar o convite. Solicite um novo link ao administrador.',
      );
    }

    final invitation = _invitations[invitationIndex];
    final preview = _invitationPreviews[invitationId];
    if (preview == null ||
        invitation.status != 'PENDENTE' ||
        invitation.expiresAt.isBefore(DateTime.now())) {
      throw const MockRepositoryException(
        'Não foi possível validar o convite. Solicite um novo link ao administrador.',
      );
    }
    return preview;
  }

  @override
  Future<OrganizationTeam> saveTeam(SaveOrganizationTeamInput input) async {
    await _latency();
    final duplicate = _teams.any(
      (team) =>
          team.name.toLowerCase() == input.name.toLowerCase() &&
          team.id != input.teamId,
    );
    if (duplicate) {
      throw const MockRepositoryException(
        'Já existe uma equipe com este nome na organização.',
      );
    }

    OrganizationTeam saved;
    final responsible = _members
        .where((member) => member.id == input.responsibleUserId)
        .firstOrNull;
    final adminName = responsible?.fullName ?? 'Responsável da equipe';
    final index = input.teamId == null
        ? -1
        : _teams.indexWhere((team) => team.id == input.teamId);
    if (index == -1) {
      saved = OrganizationTeam(
        id: 'team-${_teams.length + 1}',
        name: input.name,
        description: input.description,
        adminName: adminName,
        memberCount: 0,
        status: TeamStatus.active,
        createdAt: DateTime.now(),
        acronym: input.acronym,
        responsibleUserId: input.responsibleUserId,
      );
      _teams.insert(0, saved);
    } else {
      saved = _teams[index].copyWith(
        name: input.name,
        description: input.description,
        adminName: adminName,
        acronym: input.acronym,
        responsibleUserId: input.responsibleUserId,
      );
      _teams[index] = saved;
    }
    _events.insert(
      0,
      AuditEvent(
        id: 'evt-${_events.length + 1}',
        title: index == -1 ? 'Equipe criada' : 'Equipe atualizada',
        subtitle: 'Equipe: ${saved.name} • Admin organização',
        timeLabel: 'Agora',
        severity: AuditSeverity.operation,
        iconCode: 'team',
      ),
    );
    return saved;
  }

  @override
  Future<void> setTeamStatus({
    required String teamId,
    required TeamStatus status,
  }) async {
    await _latency();
    final index = _teams.indexWhere((team) => team.id == teamId);
    if (index == -1) {
      throw const MockRepositoryException('Equipe não encontrada.');
    }
    _teams[index] = _teams[index].copyWith(status: status);
    _events.insert(
      0,
      AuditEvent(
        id: 'evt-${_events.length + 1}',
        title: status == TeamStatus.active
            ? 'Equipe reativada'
            : 'Equipe desativada',
        subtitle: 'Equipe: ${_teams[index].name} • vínculo preservado',
        timeLabel: 'Agora',
        severity: AuditSeverity.operation,
        iconCode: 'team-status',
      ),
    );
  }

  @override
  Future<OrganizationMember> updateTeamUser(
    UpdateOrganizationMemberInput input,
  ) async {
    final index = _members.indexWhere((member) => member.id == input.userId);
    if (index == -1) {
      throw const MockRepositoryException('Usuário não encontrado.');
    }
    final current = _members[index];
    final fullName = [
      input.firstName.trim(),
      if (input.lastName?.trim().isNotEmpty ?? false) input.lastName!.trim(),
    ].join(' ');
    final updated = OrganizationMember(
      id: current.id,
      teamId: input.teamId,
      fullName: fullName,
      email: current.email,
      teamRole: input.teamRole,
      profileLabel: input.profiles.join(' • '),
      status: current.status,
      firstName: input.firstName,
      lastName: input.lastName,
      profiles: input.profiles,
      termsAcceptanceRequired: current.termsAcceptanceRequired,
    );
    _members[index] = updated;
    return updated;
  }

  @override
  Future<void> setTeamUserStatus({
    required String userId,
    required String teamId,
    required TeamMemberStatus status,
  }) async {
    final index = _members.indexWhere((member) => member.id == userId);
    if (index == -1) {
      throw const MockRepositoryException('Usuário não encontrado.');
    }
    _members[index] = _members[index].copyWith(status: status);
  }

  @override
  Future<void> disableTeamUser(String userId) async {
    final member = _members.firstWhere((item) => item.id == userId);
    await setTeamUserStatus(
      userId: userId,
      teamId: member.teamId,
      status: TeamMemberStatus.inactive,
    );
  }

  @override
  Future<String> exportAuditCsv() async =>
      'eventType,description\n${_events.map((event) => '${event.title},${event.subtitle}').join('\n')}';

  @override
  Future<List<InstitutionalPolicy>> listInstitutionalPolicies() async =>
      const [];

  @override
  Future<InstitutionalPolicy> createInstitutionalPolicy(
    SaveInstitutionalPolicyInput input,
  ) => throw const MockRepositoryException(
    'A gestão de políticas exige uma sessão real de Admin sistema.',
  );

  @override
  Future<InstitutionalPolicy> updateInstitutionalPolicy({
    required String policyId,
    required String title,
    required String type,
  }) => throw const MockRepositoryException(
    'A gestão de políticas exige uma sessão real de Admin sistema.',
  );

  @override
  Future<void> deactivateInstitutionalPolicy(String policyId) =>
      throw const MockRepositoryException(
        'A gestão de políticas exige uma sessão real de Admin sistema.',
      );

  @override
  Future<InstitutionalPolicyVersion> createInstitutionalPolicyVersion({
    required String policyId,
    required String version,
    required String content,
    required bool required,
    required DateTime effectiveAt,
  }) => throw const MockRepositoryException(
    'A gestão de políticas exige uma sessão real de Admin sistema.',
  );

  @override
  Future<InstitutionalPolicyVersion> publishInstitutionalPolicyVersion({
    required String policyId,
    required String versionId,
  }) => throw const MockRepositoryException(
    'A gestão de políticas exige uma sessão real de Admin sistema.',
  );

  void _updateTeamMemberCount(String teamId, int delta) {
    final index = _teams.indexWhere((team) => team.id == teamId);
    if (index != -1) {
      _teams[index] = _teams[index].copyWith(
        memberCount: _teams[index].memberCount + delta,
      );
    }
  }

  String _teamName(String teamId) {
    return _teams
        .firstWhere((team) => team.id == teamId, orElse: () => _teams.first)
        .name;
  }

  @override
  Future<ProtectedResource> createResource({
    required String name,
    required String description,
    required String category,
    required ResourceRisk risk,
    required String provisioning,
  }) async {
    await _latency();
    final resource = ProtectedResource(
      id: 'rec-${_resources.length + 1}',
      name: name,
      description: description,
      team: 'Equipe TI',
      category: category,
      risk: risk,
      provisioning: provisioning,
      vaultLabel: _firstAccess?.vaultType.label ?? VaultType.studyApp.label,
      lastAccessLabel: 'Nunca acessado',
      iconLabel: name.trim().isEmpty
          ? '?'
          : name.trim().substring(0, 1).toUpperCase(),
    );
    _resources.insert(0, resource);
    _events.insert(
      0,
      AuditEvent(
        id: 'evt-${_events.length + 1}',
        title: 'Recurso cadastrado',
        subtitle: 'Recurso: $name • segredo referenciado no cofre',
        timeLabel: 'Agora',
        severity: AuditSeverity.operation,
        iconCode: 'add',
      ),
    );
    return resource;
  }

  @override
  Future<AccessRequest> requestAccess({
    required ProtectedResource resource,
    required String justification,
    required String accessType,
    required int durationMinutes,
    required String priority,
  }) async {
    await _latency();
    _events.insert(
      0,
      AuditEvent(
        id: 'evt-${_events.length + 1}',
        title: 'Solicitação de acesso criada',
        subtitle: 'Recurso: ${resource.name} • prioridade $priority',
        timeLabel: 'Agora',
        severity: AuditSeverity.info,
        iconCode: 'request',
      ),
    );
    return AccessRequest(
      id: 'request-${DateTime.now().millisecondsSinceEpoch}',
      resource: resource,
      requester: 'Pessoa Exemplo',
      justification: justification,
      accessType: accessType,
      durationMinutes: durationMinutes,
      priority: priority,
      requestedAt: DateTime.now(),
    );
  }

  @override
  Future<void> decideRequest({
    required String requestId,
    required bool approve,
  }) async {
    await _latency();
    _events.insert(
      0,
      AuditEvent(
        id: 'evt-${_events.length + 1}',
        title: approve ? 'Delegação aprovada' : 'Solicitação rejeitada',
        subtitle: 'Decisão registrada • solicitação $requestId',
        timeLabel: 'Agora',
        severity: approve ? AuditSeverity.operation : AuditSeverity.alert,
        iconCode: approve ? 'approved' : 'blocked',
      ),
    );
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 260));
}

class MockRepositoryException implements Exception {
  const MockRepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}

const _initialResources = <ProtectedResource>[
  ProtectedResource(
    id: 'rec-aws-prod-001',
    name: 'AWS Produção',
    description:
        'Ambiente crítico utilizado pela equipe de infraestrutura e operações.',
    team: 'Equipe TI',
    category: 'Infraestrutura',
    risk: ResourceRisk.restricted,
    provisioning: 'QR Code',
    vaultLabel: 'Cofre digital StudyApp',
    lastAccessLabel: 'Hoje, 09:21',
    iconLabel: 'aws',
  ),
  ProtectedResource(
    id: 'rec-fin-001',
    name: 'Conta Financeiro',
    description: 'Conta corporativa do setor financeiro.',
    team: 'Financeiro',
    category: 'Financeiro',
    risk: ResourceRisk.critical,
    provisioning: 'Chave manual',
    vaultLabel: 'Cofre digital StudyApp',
    lastAccessLabel: 'Ontem, 18:12',
    iconLabel: r'$',
  ),
  ProtectedResource(
    id: 'rec-support-001',
    name: 'Sistema Suporte',
    description: 'Painel de atendimento e suporte ao usuário.',
    team: 'Atendimento',
    category: 'Operação',
    risk: ResourceRisk.moderate,
    provisioning: 'Importação',
    vaultLabel: 'Cofre da organização',
    lastAccessLabel: 'Ontem, 16:05',
    iconLabel: 'S',
  ),
];

const _initialEvents = <AuditEvent>[
  AuditEvent(
    id: 'evt-001',
    title: 'Visualização TOTP',
    subtitle: 'joao.silva • Recurso: Financeiro',
    timeLabel: '09:32',
    severity: AuditSeverity.info,
    iconCode: 'view',
  ),
  AuditEvent(
    id: 'evt-002',
    title: 'Delegação aprovada',
    subtitle: 'maria.oliveira • Recurso: Servidores',
    timeLabel: '09:15',
    severity: AuditSeverity.operation,
    iconCode: 'approved',
  ),
  AuditEvent(
    id: 'evt-003',
    title: 'Tentativa bloqueada',
    subtitle: 'IP 200.99.45.12 • Recurso: VPN',
    timeLabel: '08:47',
    severity: AuditSeverity.alert,
    iconCode: 'blocked',
  ),
];

final _initialTeams = <OrganizationTeam>[
  OrganizationTeam(
    id: 'team-ti',
    name: 'Tecnologia da Informação',
    description: 'Infraestrutura, desenvolvimento e segurança da organização.',
    adminName: 'Alexandre Gama de Deus',
    memberCount: 8,
    status: TeamStatus.active,
    createdAt: DateTime(2026, 7, 1),
  ),
  OrganizationTeam(
    id: 'team-financeiro',
    name: 'Financeiro',
    description: 'Contas, pagamentos e relatórios financeiros.',
    adminName: 'Mariana Oliveira',
    memberCount: 5,
    status: TeamStatus.active,
    createdAt: DateTime(2026, 7, 2),
  ),
  OrganizationTeam(
    id: 'team-operacoes',
    name: 'Operações',
    description: 'Operação diária e atendimento institucional.',
    adminName: 'Guilherme Santos',
    memberCount: 4,
    status: TeamStatus.inactive,
    createdAt: DateTime(2026, 7, 3),
  ),
];

const _initialMembers = <OrganizationMember>[
  OrganizationMember(
    id: 'member-joao',
    teamId: 'team-ti',
    fullName: 'Pessoa Exemplo',
    email: 'fixture-8379c1e907@example.invalid',
    teamRole: 'Responsável',
    profileLabel: 'Admin equipe',
    status: TeamMemberStatus.active,
  ),
  OrganizationMember(
    id: 'member-ana',
    teamId: 'team-ti',
    fullName: 'Ana Martins',
    email: 'fixture-36ccfaa916@example.invalid',
    teamRole: 'Aprovadora',
    profileLabel: 'Aprovador equipe',
    status: TeamMemberStatus.active,
  ),
  OrganizationMember(
    id: 'member-carlos',
    teamId: 'team-ti',
    fullName: 'Carlos Lima',
    email: 'fixture-2b946b3936@example.invalid',
    teamRole: 'Membro',
    profileLabel: 'Membro equipe',
    status: TeamMemberStatus.pending,
  ),
  OrganizationMember(
    id: 'member-mariana',
    teamId: 'team-financeiro',
    fullName: 'Mariana Oliveira',
    email: 'fixture-9adfe67c24@example.invalid',
    teamRole: 'Responsável',
    profileLabel: 'Admin equipe',
    status: TeamMemberStatus.active,
  ),
  OrganizationMember(
    id: 'member-marina',
    teamId: 'team-financeiro',
    fullName: 'Marina Alves',
    email: 'fixture-002818759c@example.invalid',
    teamRole: 'Analista',
    profileLabel: 'Membro equipe',
    status: TeamMemberStatus.pending,
  ),
];

final _initialInvitations = <TeamInvitationSummary>[
  TeamInvitationSummary(
    id: 'invite-carlos',
    teamId: 'team-ti',
    email: 'fixture-2b946b3936@example.invalid',
    expiresAt: DateTime.now().add(const Duration(hours: 43)),
    status: 'PENDENTE',
  ),
  TeamInvitationSummary(
    id: 'invite-marina',
    teamId: 'team-financeiro',
    email: 'fixture-002818759c@example.invalid',
    expiresAt: DateTime.now().add(const Duration(hours: 65)),
    status: 'PENDENTE',
  ),
];

final _initialInvitationPreviews = <TeamInvitationPreview>[
  TeamInvitationPreview(
    invitationId: 'invite-carlos',
    fullName: 'Carlos Lima',
    email: 'fixture-2b946b3936@example.invalid',
    organizationName: 'EXAMPLE-MG',
    teamName: 'Tecnologia da Informação',
    teamRole: 'Membro',
    profiles: const {'Membro equipe'},
    expiresAt: DateTime.now().add(const Duration(hours: 43)),
    accountExists: false,
    requiresTermsAcceptance: true,
  ),
  TeamInvitationPreview(
    invitationId: 'invite-marina',
    fullName: 'Marina Alves',
    email: 'fixture-002818759c@example.invalid',
    organizationName: 'EXAMPLE-MG',
    teamName: 'Financeiro',
    teamRole: 'Analista',
    profiles: const {'Membro equipe'},
    expiresAt: DateTime.now().add(const Duration(hours: 65)),
    accountExists: true,
    requiresTermsAcceptance: false,
  ),
];
