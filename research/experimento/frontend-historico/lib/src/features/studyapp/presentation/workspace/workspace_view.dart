import 'package:flutter/material.dart';

import '../../domain/studyapp_models.dart';
import '../../domain/studyapp_repository.dart';
import '../widgets/studyapp_ui.dart';
import 'audit_view.dart';
import 'dashboard_view.dart';
import 'profile_view.dart';
import 'resources_view.dart';
import 'workspace_view_model.dart';

class WorkspaceView extends StatefulWidget {
  const WorkspaceView({
    required this.data,
    required this.repository,
    required this.onChangePassword,
    required this.onLogout,
    this.onSessionInvalidated,
    super.key,
  });

  final WorkspaceData data;
  final StudyAppRepository repository;
  final Future<bool> Function({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  })
  onChangePassword;
  final VoidCallback onLogout;
  final VoidCallback? onSessionInvalidated;

  @override
  State<WorkspaceView> createState() => _WorkspaceViewState();
}

class _WorkspaceViewState extends State<WorkspaceView> {
  late final WorkspaceViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = WorkspaceViewModel(
      repository: widget.repository,
      data: widget.data,
      onSessionInvalidated: widget.onSessionInvalidated,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final sections = _viewModel.visibleSections;
        final pages = sections
            .map(
              (section) => switch (section) {
                WorkspaceSection.dashboard => DashboardView(
                  viewModel: _viewModel,
                ),
                WorkspaceSection.resources => ResourcesView(
                  viewModel: _viewModel,
                ),
                WorkspaceSection.audit => AuditView(viewModel: _viewModel),
                WorkspaceSection.profile => ProfileView(
                  viewModel: _viewModel,
                  onChangePassword: widget.onChangePassword,
                  onLogout: widget.onLogout,
                ),
              },
            )
            .toList(growable: false);
        return NavyPage(
          bottomNavigationBar: NavigationBar(
            selectedIndex: _viewModel.selectedTab,
            backgroundColor: const Color(0xFF0B2A64),
            indicatorColor: const Color(0xFF174A9B),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                color: states.contains(WidgetState.selected)
                    ? const Color(0xFF8FBEFF)
                    : Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            onDestinationSelected: _viewModel.selectTab,
            destinations: sections.map(_destination).toList(growable: false),
          ),
          child: IndexedStack(index: _viewModel.selectedTab, children: pages),
        );
      },
    );
  }

  NavigationDestination _destination(WorkspaceSection section) =>
      switch (section) {
        WorkspaceSection.dashboard => const NavigationDestination(
          icon: Icon(Icons.home_outlined, color: Colors.white70),
          selectedIcon: Icon(Icons.home, color: Color(0xFF60A5FA)),
          label: 'Início',
        ),
        WorkspaceSection.resources => const NavigationDestination(
          icon: Icon(Icons.layers_outlined, color: Colors.white70),
          selectedIcon: Icon(Icons.layers, color: Color(0xFF60A5FA)),
          label: 'Recursos',
        ),
        WorkspaceSection.audit => const NavigationDestination(
          icon: Icon(Icons.shield_outlined, color: Colors.white70),
          selectedIcon: Icon(Icons.shield, color: Color(0xFF60A5FA)),
          label: 'Auditoria',
        ),
        WorkspaceSection.profile => const NavigationDestination(
          icon: Icon(Icons.person_outline, color: Colors.white70),
          selectedIcon: Icon(Icons.person, color: Color(0xFF60A5FA)),
          label: 'Perfil',
        ),
      };

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
