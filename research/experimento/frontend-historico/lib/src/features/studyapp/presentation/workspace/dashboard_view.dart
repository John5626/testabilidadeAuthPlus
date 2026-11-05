import 'package:flutter/material.dart';

import '../../domain/studyapp_models.dart';
import '../widgets/studyapp_ui.dart';
import 'approval_view.dart';
import 'identity_administration_view.dart';
import 'resource_form_view.dart';
import 'workspace_view_model.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({required this.viewModel, super.key});
  final WorkspaceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final data = viewModel.data.dashboard;
    return ContentWidth(
      maxWidth: 780,
      child: CustomScrollView(
        key: const PageStorageKey('dashboard-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: AppTopBar(
              actions: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF60A5FA),
                  child: Text(
                    data.userName.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            sliver: SliverList.list(
              children: [
                SectionTitle(
                  'Olá, ${data.userName}!',
                  subtitle: 'Gerencie seus acessos com segurança.',
                ),
                const SizedBox(height: 20),
                _metrics(data),
                const SizedBox(height: 30),
                _subheading(context, 'Ações rápidas'),
                const SizedBox(height: 14),
                _quickActions(context),
                if (viewModel.data.profile.canAudit) ...[
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: _subheading(context, 'Atividades recentes'),
                      ),
                      TextButton(
                        onPressed: () =>
                            viewModel.selectSection(WorkspaceSection.audit),
                        child: const Text('Ver todas'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      children: data.recentEvents
                          .map((event) => _eventRow(context, event))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metrics(DashboardData data) {
    final metrics = [
      (
        Icons.layers,
        '${data.resourceCount}',
        'Recursos',
        const Color(0xFF60A5FA),
      ),
      (
        Icons.groups,
        '${data.activeDelegations}',
        'Delegações',
        const Color(0xFF2FBB73),
      ),
      (
        Icons.hourglass_top,
        '${data.pendingRequests}',
        'Pendências',
        const Color(0xFFFFB14D),
      ),
      (
        Icons.warning_rounded,
        '${data.alertCount}',
        'Alertas',
        const Color(0xFFFF7272),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 30) / 4;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: metrics
              .map(
                (item) => Container(
                  width: width < 112 ? (constraints.maxWidth - 10) / 2 : width,
                  constraints: const BoxConstraints(minHeight: 108),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2D6A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1A438F)),
                  ),
                  child: Column(
                    children: [
                      Icon(item.$1, color: item.$4, size: 30),
                      const SizedBox(height: 7),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        item.$3,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFC8D7FF),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _quickActions(BuildContext context) {
    final profile = viewModel.data.profile;
    final actions = <(IconData, String, VoidCallback)>[
      if (profile.resourceFeaturesAvailable && profile.canUseResources)
        (
          Icons.add,
          'Novo recurso',
          () => viewModel.data.profile.resourceFeaturesAvailable
              ? Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ResourceFormView(viewModel: viewModel),
                  ),
                )
              : showPrototypeMessage(
                  context,
                  'O backend ainda não disponibiliza recursos TOTP.',
                ),
        ),
      if (profile.resourceFeaturesAvailable && profile.canApproveRequests)
        (
          Icons.person_add_alt_1,
          'Acessos',
          () => viewModel.data.profile.resourceFeaturesAvailable
              ? Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ApprovalView(
                      viewModel: viewModel,
                      request: viewModel.data.pendingRequest,
                    ),
                  ),
                )
              : showPrototypeMessage(
                  context,
                  'O backend ainda não disponibiliza solicitações de acesso.',
                ),
        ),
      if (profile.canAudit)
        (
          Icons.shield_outlined,
          'Auditoria',
          () => viewModel.selectSection(WorkspaceSection.audit),
        ),
      if (profile.canInviteTeamUsers ||
          profile.canManageTeams ||
          profile.canManagePolicies)
        (
          Icons.manage_accounts_outlined,
          'Administração',
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => IdentityAdministrationView(viewModel: viewModel),
            ),
          ),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 5 : 3;
        final width = (constraints.maxWidth - ((columns - 1) * 8)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions
              .map(
                (action) => SizedBox(
                  width: width,
                  child: InkWell(
                    onTap: action.$3,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 94,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2D6A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1A438F)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            action.$1,
                            color: const Color(0xFF8FBEFF),
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            action.$2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _eventRow(BuildContext context, AuditEvent event) {
    final color = switch (event.severity) {
      AuditSeverity.info => const Color(0xFF60A5FA),
      AuditSeverity.operation => const Color(0xFF70F0A4),
      AuditSeverity.alert => const Color(0xFFFF7C8B),
    };
    final icon = switch (event.severity) {
      AuditSeverity.info => Icons.visibility_outlined,
      AuditSeverity.operation => Icons.check_circle_outline,
      AuditSeverity.alert => Icons.warning_amber_rounded,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.18),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  event.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB8C7E8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            event.timeLabel,
            style: const TextStyle(color: Color(0xFFB8C7E8), fontSize: 11),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }

  Widget _subheading(BuildContext context, String label) => Text(
    label,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
    ),
  );
}
