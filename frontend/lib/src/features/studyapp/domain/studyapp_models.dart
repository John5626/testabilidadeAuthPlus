import '../../resource_revelation/domain/revelation.dart';
import 'authentication.dart';

enum VaultType { organization, studyApp }

extension VaultTypeLabel on VaultType {
  String get label => switch (this) {
    VaultType.organization => 'Cofre da organização',
    VaultType.studyApp => 'Cofre gerenciado StudyApp',
  };
}

class RegistrationDraft {
  const RegistrationDraft({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.organizationName,
    required this.organizationDomain,
    required this.teamName,
    required this.personalDataConsentAccepted,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String organizationName;
  final String organizationDomain;
  final String teamName;
  final bool personalDataConsentAccepted;
}

class FirstAccessSetup {
  const FirstAccessSetup({
    required this.phone,
    required this.jobTitle,
    required this.termsAccepted,
    required this.twoFactorEnabled,
    required this.vaultType,
    this.vaultName,
    this.vaultEndpoint,
  });

  final String phone;
  final String jobTitle;
  final bool termsAccepted;
  final bool twoFactorEnabled;
  final VaultType vaultType;
  final String? vaultName;
  final String? vaultEndpoint;
}

enum ResourceRisk { critical, moderate, restricted }

extension ResourceRiskLabel on ResourceRisk {
  String get label => switch (this) {
    ResourceRisk.critical => 'Crítico',
    ResourceRisk.moderate => 'Moderado',
    ResourceRisk.restricted => 'Restrito',
  };
}

class ProtectedResource {
  const ProtectedResource({
    required this.id,
    required this.name,
    required this.description,
    required this.team,
    required this.category,
    required this.risk,
    required this.provisioning,
    required this.vaultLabel,
    required this.lastAccessLabel,
    required this.iconLabel,
    this.revelationResource,
  });

  final String id;
  final String name;
  final String description;
  final String team;
  final String category;
  final ResourceRisk risk;
  final String provisioning;
  final String vaultLabel;
  final String lastAccessLabel;
  final String iconLabel;
  final RevelationResource? revelationResource;
  String get criticalityLabel =>
      revelationResource?.criticalityLabel ?? risk.label;
}

enum AuditSeverity { info, operation, alert }

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.severity,
    required this.iconCode,
  });

  final String id;
  final String title;
  final String subtitle;
  final String timeLabel;
  final AuditSeverity severity;
  final String iconCode;
}

class AccessRequest {
  const AccessRequest({
    required this.id,
    required this.resource,
    required this.requester,
    required this.justification,
    required this.accessType,
    required this.durationMinutes,
    required this.priority,
    required this.requestedAt,
  });

  final String id;
  final ProtectedResource resource;
  final String requester;
  final String justification;
  final String accessType;
  final int durationMinutes;
  final String priority;
  final DateTime requestedAt;
}

class DashboardData {
  const DashboardData({
    required this.userName,
    required this.resourceCount,
    required this.activeDelegations,
    required this.pendingRequests,
    required this.alertCount,
    required this.recentEvents,
  });

  final String userName;
  final int resourceCount;
  final int activeDelegations;
  final int pendingRequests;
  final int alertCount;
  final List<AuditEvent> recentEvents;
}

class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.email,
    required this.organization,
    required this.team,
    required this.role,
    required this.phone,
    required this.twoFactorEnabled,
    required this.vaultType,
    required this.canInviteTeamUsers,
    required this.canManageTeams,
    this.canManagePolicies = false,
    this.canAudit = false,
    this.resourceFeaturesAvailable = true,
    this.canApproveRequests = false,
    this.canUseResources = false,
  });

  final String fullName;
  final String email;
  final String organization;
  final String team;
  final String role;
  final String phone;
  final bool twoFactorEnabled;
  final VaultType vaultType;
  final bool canInviteTeamUsers;
  final bool canManageTeams;
  final bool canManagePolicies;
  final bool canAudit;
  final bool resourceFeaturesAvailable;
  final bool canApproveRequests;
  final bool canUseResources;
}

enum TeamStatus { active, inactive }

extension TeamStatusLabel on TeamStatus {
  String get label => switch (this) {
    TeamStatus.active => 'Ativa',
    TeamStatus.inactive => 'Inativa',
  };
}

enum TeamMemberStatus { active, pending, blocked, inactive }

extension TeamMemberStatusLabel on TeamMemberStatus {
  String get label => switch (this) {
    TeamMemberStatus.active => 'Ativo',
    TeamMemberStatus.pending => 'Convite pendente',
    TeamMemberStatus.blocked => 'Bloqueado',
    TeamMemberStatus.inactive => 'Desativado',
  };
}

class OrganizationTeam {
  const OrganizationTeam({
    required this.id,
    required this.name,
    required this.description,
    required this.adminName,
    required this.memberCount,
    required this.status,
    required this.createdAt,
    this.acronym,
    this.responsibleUserId,
  });

  final String id;
  final String name;
  final String description;
  final String adminName;
  final int memberCount;
  final TeamStatus status;
  final DateTime createdAt;
  final String? acronym;
  final String? responsibleUserId;

  OrganizationTeam copyWith({
    String? name,
    String? description,
    String? adminName,
    int? memberCount,
    TeamStatus? status,
    String? acronym,
    String? responsibleUserId,
  }) {
    return OrganizationTeam(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminName: adminName ?? this.adminName,
      memberCount: memberCount ?? this.memberCount,
      status: status ?? this.status,
      createdAt: createdAt,
      acronym: acronym ?? this.acronym,
      responsibleUserId: responsibleUserId ?? this.responsibleUserId,
    );
  }
}

class OrganizationMember {
  const OrganizationMember({
    required this.id,
    required this.teamId,
    required this.fullName,
    required this.email,
    required this.teamRole,
    required this.profileLabel,
    required this.status,
    this.firstName = '',
    this.lastName,
    this.profiles = const {},
    this.termsAcceptanceRequired = false,
  });

  final String id;
  final String teamId;
  final String fullName;
  final String email;
  final String teamRole;
  final String profileLabel;
  final TeamMemberStatus status;
  final String firstName;
  final String? lastName;
  final Set<String> profiles;
  final bool termsAcceptanceRequired;

  OrganizationMember copyWith({TeamMemberStatus? status}) {
    return OrganizationMember(
      id: id,
      teamId: teamId,
      fullName: fullName,
      email: email,
      teamRole: teamRole,
      profileLabel: profileLabel,
      status: status ?? this.status,
      firstName: firstName,
      lastName: lastName,
      profiles: profiles,
      termsAcceptanceRequired: termsAcceptanceRequired,
    );
  }
}

class TeamInvitationSummary {
  const TeamInvitationSummary({
    required this.id,
    required this.teamId,
    required this.email,
    required this.expiresAt,
    required this.status,
  });

  final String id;
  final String teamId;
  final String email;
  final DateTime expiresAt;
  final String status;

  TeamInvitationSummary copyWith({String? status}) {
    return TeamInvitationSummary(
      id: id,
      teamId: teamId,
      email: email,
      expiresAt: expiresAt,
      status: status ?? this.status,
    );
  }
}

class TeamInvitationReceipt {
  const TeamInvitationReceipt({
    required this.invitation,
    required this.member,
    required this.oneTimeToken,
  });

  final TeamInvitationSummary invitation;
  final OrganizationMember member;
  final String oneTimeToken;
}

class InviteTeamUserInput {
  const InviteTeamUserInput({
    required this.teamId,
    required this.firstName,
    this.lastName,
    required this.email,
    required this.teamRole,
    required this.profiles,
  });

  final String teamId;
  final String firstName;
  final String? lastName;
  final String email;
  final String teamRole;
  final Set<String> profiles;
}

class TeamInvitationPreview {
  const TeamInvitationPreview({
    required this.invitationId,
    required this.fullName,
    required this.email,
    required this.organizationName,
    required this.teamName,
    required this.teamRole,
    required this.profiles,
    required this.expiresAt,
    required this.accountExists,
    required this.requiresTermsAcceptance,
    this.policies = const [],
  });

  final String invitationId;
  final String fullName;
  final String email;
  final String organizationName;
  final String teamName;
  final String teamRole;
  final Set<String> profiles;
  final DateTime expiresAt;
  final bool accountExists;
  final bool requiresTermsAcceptance;
  final List<RequiredPolicy> policies;
}

class AcceptTeamInvitationInput {
  const AcceptTeamInvitationInput({
    required this.token,
    required this.password,
    required this.passwordConfirmation,
    required this.personalDataConsentAccepted,
    this.policyVersionIds = const {},
  });

  final String token;
  final String password;
  final String passwordConfirmation;
  final bool personalDataConsentAccepted;
  final Set<String> policyVersionIds;
}

class TeamInvitationAcceptance {
  const TeamInvitationAcceptance({
    required this.email,
    required this.teamName,
    required this.accountCreated,
    required this.requiresFirstAccess,
    this.session,
  });

  final String email;
  final String teamName;
  final bool accountCreated;
  final bool requiresFirstAccess;
  final AuthenticatedSession? session;
}

class SaveOrganizationTeamInput {
  const SaveOrganizationTeamInput({
    required this.name,
    required this.description,
    required this.responsibleUserId,
    this.teamId,
    this.acronym,
  });

  final String? teamId;
  final String name;
  final String description;
  final String responsibleUserId;
  final String? acronym;
}

class UpdateOrganizationMemberInput {
  const UpdateOrganizationMemberInput({
    required this.userId,
    required this.teamId,
    required this.firstName,
    this.lastName,
    required this.teamRole,
    required this.profiles,
  });

  final String userId;
  final String teamId;
  final String firstName;
  final String? lastName;
  final String teamRole;
  final Set<String> profiles;
}

class InstitutionalPolicyVersion {
  const InstitutionalPolicyVersion({
    required this.id,
    required this.version,
    required this.content,
    required this.required,
    required this.status,
    required this.effectiveAt,
    required this.createdAt,
    this.publishedAt,
  });

  final String id;
  final String version;
  final String content;
  final bool required;
  final String status;
  final DateTime effectiveAt;
  final DateTime? publishedAt;
  final DateTime createdAt;
}

class InstitutionalPolicy {
  const InstitutionalPolicy({
    required this.id,
    required this.code,
    required this.title,
    required this.type,
    required this.status,
    required this.versions,
  });

  final String id;
  final String code;
  final String title;
  final String type;
  final String status;
  final List<InstitutionalPolicyVersion> versions;
}

class SaveInstitutionalPolicyInput {
  const SaveInstitutionalPolicyInput({
    required this.code,
    required this.title,
    required this.type,
    required this.version,
    required this.content,
    required this.required,
    required this.effectiveAt,
  });

  final String code;
  final String title;
  final String type;
  final String version;
  final String content;
  final bool required;
  final DateTime effectiveAt;
}

class WorkspaceData {
  const WorkspaceData({
    required this.dashboard,
    required this.resources,
    required this.auditEvents,
    required this.pendingRequest,
    required this.profile,
    required this.teams,
    required this.members,
    required this.invitations,
  });

  final DashboardData dashboard;
  final List<ProtectedResource> resources;
  final List<AuditEvent> auditEvents;
  final AccessRequest pendingRequest;
  final UserProfile profile;
  final List<OrganizationTeam> teams;
  final List<OrganizationMember> members;
  final List<TeamInvitationSummary> invitations;
}
