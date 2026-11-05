import 'studyapp_models.dart';

class IdentitySessionInvalidException implements Exception {
  const IdentitySessionInvalidException();

  @override
  String toString() => 'Sua sessão não está mais disponível. Entre novamente.';
}

abstract class StudyAppRepository {
  Future<void> completeFirstAccess(FirstAccessSetup setup);

  Future<WorkspaceData> loadWorkspace();

  Future<ProtectedResource> createResource({
    required String name,
    required String description,
    required String category,
    required ResourceRisk risk,
    required String provisioning,
  });

  Future<AccessRequest> requestAccess({
    required ProtectedResource resource,
    required String justification,
    required String accessType,
    required int durationMinutes,
    required String priority,
  });

  Future<void> decideRequest({
    required String requestId,
    required bool approve,
  });

  Future<TeamInvitationReceipt> inviteTeamUser(InviteTeamUserInput input);

  Future<TeamInvitationPreview> validateTeamInvitation(String token);

  Future<TeamInvitationAcceptance> acceptTeamInvitation(
    AcceptTeamInvitationInput input,
  );

  Future<OrganizationTeam> saveTeam(SaveOrganizationTeamInput input);

  Future<void> setTeamStatus({
    required String teamId,
    required TeamStatus status,
  });

  Future<OrganizationMember> updateTeamUser(
    UpdateOrganizationMemberInput input,
  );

  Future<void> setTeamUserStatus({
    required String userId,
    required String teamId,
    required TeamMemberStatus status,
  });

  Future<void> disableTeamUser(String userId);

  Future<String> exportAuditCsv();

  Future<List<InstitutionalPolicy>> listInstitutionalPolicies();

  Future<InstitutionalPolicy> createInstitutionalPolicy(
    SaveInstitutionalPolicyInput input,
  );

  Future<InstitutionalPolicy> updateInstitutionalPolicy({
    required String policyId,
    required String title,
    required String type,
  });

  Future<void> deactivateInstitutionalPolicy(String policyId);

  Future<InstitutionalPolicyVersion> createInstitutionalPolicyVersion({
    required String policyId,
    required String version,
    required String content,
    required bool required,
    required DateTime effectiveAt,
  });

  Future<InstitutionalPolicyVersion> publishInstitutionalPolicyVersion({
    required String policyId,
    required String versionId,
  });
}
