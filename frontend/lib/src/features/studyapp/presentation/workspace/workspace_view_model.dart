import 'package:flutter/foundation.dart';

import '../../domain/studyapp_models.dart';
import '../../domain/studyapp_repository.dart';

enum WorkspaceSection { dashboard, resources, audit, profile }

class WorkspaceViewModel extends ChangeNotifier {
  WorkspaceViewModel({
    required this.repository,
    required this.data,
    this.onSessionInvalidated,
  });

  final StudyAppRepository repository;
  final VoidCallback? onSessionInvalidated;
  WorkspaceData data;
  WorkspaceSection _selectedSection = WorkspaceSection.dashboard;
  String _resourceQuery = '';
  bool _busy = false;

  List<WorkspaceSection> get visibleSections => [
    WorkspaceSection.dashboard,
    if (data.profile.resourceFeaturesAvailable) WorkspaceSection.resources,
    if (data.profile.canAudit) WorkspaceSection.audit,
    WorkspaceSection.profile,
  ];
  int get selectedTab => visibleSections
      .indexOf(_selectedSection)
      .clamp(0, visibleSections.length - 1);
  bool get isBusy => _busy;

  List<ProtectedResource> get filteredResources {
    final query = _resourceQuery.toLowerCase();
    if (query.isEmpty) return data.resources;
    return data.resources.where((resource) {
      return resource.name.toLowerCase().contains(query) ||
          resource.team.toLowerCase().contains(query) ||
          resource.category.toLowerCase().contains(query);
    }).toList();
  }

  void selectTab(int value) {
    if (value < 0 || value >= visibleSections.length) return;
    _selectedSection = visibleSections[value];
    notifyListeners();
  }

  void selectSection(WorkspaceSection section) {
    if (!visibleSections.contains(section)) return;
    _selectedSection = section;
    notifyListeners();
  }

  void searchResources(String value) {
    _resourceQuery = value.trim();
    notifyListeners();
  }

  Future<ProtectedResource> createResource({
    required String name,
    required String description,
    required String category,
    required ResourceRisk risk,
    required String provisioning,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      final resource = await guardSession(
        () => repository.createResource(
          name: name,
          description: description,
          category: category,
          risk: risk,
          provisioning: provisioning,
        ),
      );
      await refresh();
      return resource;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AccessRequest> requestAccess({
    required ProtectedResource resource,
    required String justification,
    required String accessType,
    required int durationMinutes,
    required String priority,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      final request = await guardSession(
        () => repository.requestAccess(
          resource: resource,
          justification: justification,
          accessType: accessType,
          durationMinutes: durationMinutes,
          priority: priority,
        ),
      );
      await refresh();
      return request;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> decideRequest(String requestId, bool approve) async {
    _busy = true;
    notifyListeners();
    try {
      await guardSession(
        () => repository.decideRequest(requestId: requestId, approve: approve),
      );
      await refresh();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<TeamInvitationReceipt> inviteTeamUser(
    InviteTeamUserInput input,
  ) async {
    _busy = true;
    notifyListeners();
    try {
      final receipt = await guardSession(
        () => repository.inviteTeamUser(input),
      );
      await refresh();
      return receipt;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<OrganizationTeam> saveTeam(SaveOrganizationTeamInput input) async {
    _busy = true;
    notifyListeners();
    try {
      final team = await guardSession(() => repository.saveTeam(input));
      await refresh();
      return team;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> setTeamStatus(OrganizationTeam team, TeamStatus status) async {
    _busy = true;
    notifyListeners();
    try {
      await guardSession(
        () => repository.setTeamStatus(teamId: team.id, status: status),
      );
      await refresh();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> updateTeamUser(UpdateOrganizationMemberInput input) async {
    _busy = true;
    notifyListeners();
    try {
      await guardSession(() => repository.updateTeamUser(input));
      await refresh();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> setTeamUserStatus(
    OrganizationMember member,
    TeamMemberStatus status,
  ) async {
    _busy = true;
    notifyListeners();
    try {
      await guardSession(
        () => repository.setTeamUserStatus(
          userId: member.id,
          teamId: member.teamId,
          status: status,
        ),
      );
      await refresh();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> disableTeamUser(OrganizationMember member) async {
    _busy = true;
    notifyListeners();
    try {
      await guardSession(
        () => repository.setTeamUserStatus(
          userId: member.id,
          teamId: member.teamId,
          status: TeamMemberStatus.inactive,
        ),
      );
      await refresh();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String> exportAuditCsv() => guardSession(repository.exportAuditCsv);

  Future<T> guardSession<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on IdentitySessionInvalidException {
      onSessionInvalidated?.call();
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      data = await repository.loadWorkspace();
      notifyListeners();
    } on IdentitySessionInvalidException {
      final callback = onSessionInvalidated;
      if (callback == null) rethrow;
      callback();
    }
  }
}
