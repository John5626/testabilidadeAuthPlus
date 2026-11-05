enum TeamRole {
  membro('MEMBRO', 'Membro'),
  responsavel('RESPONSAVEL', 'Responsavel'),
  aprovador('APROVADOR', 'Aprovador');

  const TeamRole(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TeamRole fromApi(String value) {
    return TeamRole.values.firstWhere(
      (role) => role.apiValue == value,
      orElse: () => TeamRole.membro,
    );
  }
}

enum AccessProfile {
  adminSistema(
    'ADMIN_SISTEMA',
    'Admin sistema',
    'Administração global do sistema.',
    false,
  ),
  adminOrganizacao(
    'ADMIN_ORGANIZACAO',
    'Admin organização',
    'Gerencia usuários e equipes da organização vinculada.',
    false,
  ),
  adminEquipe(
    'ADMIN_EQUIPE',
    'Admin equipe',
    'Gerencia usuários somente nas equipes vinculadas.',
    true,
  ),
  auditor(
    'AUDITOR',
    'Auditor',
    'Consulta e exporta auditoria da organização vinculada.',
    false,
  ),
  aprovadorEquipe(
    'APROVADOR_EQUIPE',
    'Aprovador equipe',
    'Aprova solicitações no escopo da equipe.',
    true,
  ),
  membroEquipe(
    'MEMBRO_EQUIPE',
    'Membro equipe',
    'Acesso basico aos fluxos permitidos.',
    true,
  );

  const AccessProfile(
    this.apiValue,
    this.label,
    this.description,
    this.assignableByTeamAdmin,
  );

  final String apiValue;
  final String label;
  final String description;
  final bool assignableByTeamAdmin;

  static AccessProfile fromApi(String value) {
    return AccessProfile.values.firstWhere(
      (profile) => profile.apiValue == value,
      orElse: () => AccessProfile.membroEquipe,
    );
  }
}

enum UserStatus {
  pending('PENDING', 'Pendente'),
  active('ACTIVE', 'Ativo'),
  blocked('BLOCKED', 'Bloqueado'),
  disabled('DISABLED', 'Desativado');

  const UserStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static UserStatus fromApi(String value) {
    return UserStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => UserStatus.pending,
    );
  }
}

class UserManagementContext {
  const UserManagementContext({
    required this.organizationId,
    required this.teamId,
    required this.actorUserId,
  });

  final String organizationId;
  final String teamId;
  final String actorUserId;

  bool get isComplete {
    return organizationId.trim().isNotEmpty &&
        teamId.trim().isNotEmpty &&
        actorUserId.trim().isNotEmpty;
  }
}

class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.status,
    required this.organizationId,
    required this.teamId,
    required this.teamName,
    required this.teamRole,
    required this.profiles,
    required this.createdAt,
    required this.updatedAt,
    required this.termsAcceptanceRequired,
    this.invitation,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    final rawProfiles = json['profiles'] as List<dynamic>? ?? const [];

    return ManagedUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      status: UserStatus.fromApi(json['status'] as String),
      organizationId: json['organizationId'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      teamRole: TeamRole.fromApi(json['teamRole'] as String),
      profiles: rawProfiles
          .map((profile) => AccessProfile.fromApi(profile as String))
          .toSet(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      termsAcceptanceRequired: json['termsAcceptanceRequired'] as bool,
      invitation: json['invitation'] == null
          ? null
          : ManagedUserInvitation.fromJson(
              json['invitation'] as Map<String, dynamic>,
            ),
    );
  }

  final String id;
  final String email;
  final String displayName;
  final UserStatus status;
  final String organizationId;
  final String teamId;
  final String teamName;
  final TeamRole teamRole;
  final Set<AccessProfile> profiles;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool termsAcceptanceRequired;
  final ManagedUserInvitation? invitation;

  ManagedUser copyWith({
    String? id,
    String? email,
    String? displayName,
    UserStatus? status,
    String? organizationId,
    String? teamId,
    String? teamName,
    TeamRole? teamRole,
    Set<AccessProfile>? profiles,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? termsAcceptanceRequired,
    ManagedUserInvitation? invitation,
  }) {
    return ManagedUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamRole: teamRole ?? this.teamRole,
      profiles: profiles ?? this.profiles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      termsAcceptanceRequired:
          termsAcceptanceRequired ?? this.termsAcceptanceRequired,
      invitation: invitation ?? this.invitation,
    );
  }

  ManagedUser withoutInvitation() {
    return ManagedUser(
      id: id,
      email: email,
      displayName: displayName,
      status: status,
      organizationId: organizationId,
      teamId: teamId,
      teamName: teamName,
      teamRole: teamRole,
      profiles: profiles,
      createdAt: createdAt,
      updatedAt: updatedAt,
      termsAcceptanceRequired: termsAcceptanceRequired,
    );
  }
}

class ManagedUserInvitation {
  const ManagedUserInvitation({required this.token, required this.expiresAt});

  factory ManagedUserInvitation.fromJson(Map<String, dynamic> json) {
    return ManagedUserInvitation(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  final String token;
  final DateTime expiresAt;
}

class CreateManagedUserInput {
  const CreateManagedUserInput({
    required this.teamId,
    required this.email,
    required this.displayName,
    required this.teamRole,
    required this.profiles,
  });

  final String teamId;
  final String email;
  final String displayName;
  final TeamRole teamRole;
  final Set<AccessProfile> profiles;

  Map<String, Object> toJson() {
    final names = _splitDisplayName(displayName);
    return {
      'teamId': teamId.trim(),
      'email': email.trim(),
      'firstName': names.$1,
      if (names.$2 != null) 'lastName': names.$2!,
      'teamRole': teamRole.apiValue,
      'profiles': profiles.map((profile) => profile.apiValue).toList(),
    };
  }
}

class UpdateManagedUserInput {
  const UpdateManagedUserInput({
    required this.teamId,
    required this.displayName,
    required this.teamRole,
    required this.profiles,
  });

  final String teamId;
  final String displayName;
  final TeamRole teamRole;
  final Set<AccessProfile> profiles;

  Map<String, Object> toJson() {
    final names = _splitDisplayName(displayName);
    return {
      'teamId': teamId.trim(),
      'firstName': names.$1,
      if (names.$2 != null) 'lastName': names.$2!,
      'teamRole': teamRole.apiValue,
      'profiles': profiles.map((profile) => profile.apiValue).toList(),
    };
  }
}

(String, String?) _splitDisplayName(String value) {
  final parts = value.trim().split(RegExp(r'\s+'));
  final lastName = parts.skip(1).join(' ');
  return (parts.first, lastName.isEmpty ? null : lastName);
}
