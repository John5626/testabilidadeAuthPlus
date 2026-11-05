import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/studyapp_models.dart';
import '../widgets/studyapp_ui.dart';
import 'invite_team_user_view.dart';
import 'organization_team_form_view.dart';
import 'workspace_view_model.dart';

class IdentityAdministrationView extends StatefulWidget {
  const IdentityAdministrationView({required this.viewModel, super.key});

  final WorkspaceViewModel viewModel;

  @override
  State<IdentityAdministrationView> createState() =>
      _IdentityAdministrationViewState();
}

class _IdentityAdministrationViewState
    extends State<IdentityAdministrationView> {
  var _section = 0;
  String? _selectedTeamId;
  String _teamQuery = '';

  @override
  Widget build(BuildContext context) {
    final teams = widget.viewModel.data.teams;
    _selectedTeamId ??= teams.firstOrNull?.id;
    return NavyPage(
      child: ContentWidth(
        maxWidth: 780,
        child: Column(
          children: [
            AppTopBar(onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle(
                      'Administração',
                      subtitle:
                          'Convide pessoas para sua equipe e organize os times da organização.',
                    ),
                    const SizedBox(height: 14),
                    _scopeBanner(),
                    const SizedBox(height: 14),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.group_add_outlined),
                          label: Text('Minha equipe'),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.account_tree_outlined),
                          label: Text('Equipes'),
                        ),
                      ],
                      selected: {_section},
                      onSelectionChanged: (value) {
                        setState(() => _section = value.first);
                      },
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        foregroundColor: const WidgetStatePropertyAll(
                          Colors.white,
                        ),
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? StudyAppColors.accent
                              : const Color(0xFF0D2D6A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _section == 0
                          ? _teamUsersSection(teams)
                          : _organizationTeamsSection(teams),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scopeBanner() {
    final profile = widget.viewModel.data.profile;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFF70F0A4)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escopo administrativo ativo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${profile.organization} • Admin organização e Admin equipe',
                  style: const TextStyle(
                    color: Color(0xFFC8D7FF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamUsersSection(List<OrganizationTeam> teams) {
    if (teams.isEmpty) {
      return const GlassCard(
        child: Text(
          'Nenhuma equipe disponível no seu escopo. Atualize a tela ou procure o administrador da organização.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    final selectedTeam = teams.firstWhere(
      (team) => team.id == _selectedTeamId,
      orElse: () => teams.first,
    );
    final members = widget.viewModel.data.members
        .where((member) => member.teamId == selectedTeam.id)
        .toList();
    final invitations = widget.viewModel.data.invitations
        .where((invitation) => invitation.teamId == selectedTeam.id)
        .toList();

    return Column(
      key: const ValueKey('team-users'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Equipe administrada',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedTeam.id,
                isExpanded: true,
                dropdownColor: const Color(0xFF0D2D6A),
                style: const TextStyle(color: Colors.white),
                decoration: _darkInput('Selecione uma equipe'),
                items: teams
                    .where((team) => team.status == TeamStatus.active)
                    .map(
                      (team) => DropdownMenuItem(
                        value: team.id,
                        child: Text(team.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedTeamId = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metric(
                Icons.people_outline,
                '${members.length}',
                'Membros',
                const Color(0xFF60A5FA),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metric(
                Icons.outgoing_mail,
                '${invitations.length}',
                'Convites',
                const Color(0xFFFFB14D),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metric(
                Icons.check_circle_outline,
                '${members.where((m) => m.status == TeamMemberStatus.active).length}',
                'Ativos',
                const Color(0xFF70F0A4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('open-invite-user'),
          onPressed: widget.viewModel.data.profile.canInviteTeamUsers
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InviteTeamUserView(
                      viewModel: widget.viewModel,
                      team: selectedTeam,
                    ),
                  ),
                )
              : null,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Convidar usuário para a equipe'),
        ),
        if (invitations.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionHeading(
            'Convites pendentes',
            '${invitations.length} aguardando',
          ),
          const SizedBox(height: 10),
          ...invitations.map(_invitationCard),
        ],
        const SizedBox(height: 20),
        _sectionHeading('Usuários da equipe', '${members.length} pessoas'),
        const SizedBox(height: 10),
        ...members.map(_memberCard),
      ],
    );
  }

  Widget _organizationTeamsSection(List<OrganizationTeam> teams) {
    final filtered = teams.where((team) {
      return '${team.name} ${team.adminName}'.toLowerCase().contains(
        _teamQuery.toLowerCase(),
      );
    }).toList();
    final activeCount = teams
        .where((team) => team.status == TeamStatus.active)
        .length;
    final totalMembers = teams.fold<int>(
      0,
      (total, team) => total + team.memberCount,
    );
    return Column(
      key: const ValueKey('organization-teams'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 170,
              child: _metric(
                Icons.account_tree_outlined,
                '$activeCount',
                'Equipes ativas',
                const Color(0xFF60A5FA),
              ),
            ),
            SizedBox(
              width: 170,
              child: _metric(
                Icons.groups_outlined,
                '$totalMembers',
                'Usuários vinculados',
                const Color(0xFF70F0A4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _teamQuery = value),
                style: const TextStyle(color: Colors.white),
                decoration: _darkInput(
                  'Buscar equipe ou administrador',
                ).copyWith(prefixIcon: const Icon(Icons.search)),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              key: const Key('open-create-team'),
              onPressed: widget.viewModel.data.profile.canManageTeams
                  ? () => _openTeamForm()
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Nova'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...filtered.map(_teamCard),
      ],
    );
  }

  Widget _metric(IconData icon, String value, String label, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB8C7E8), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _memberCard(OrganizationMember member) {
    final color = switch (member.status) {
      TeamMemberStatus.active => const Color(0xFF70F0A4),
      TeamMemberStatus.pending => const Color(0xFFFFB14D),
      TeamMemberStatus.blocked => const Color(0xFFFF7C8B),
      TeamMemberStatus.inactive => const Color(0xFFB8C7E8),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF2563EB),
              child: Text(
                _initials(member.fullName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    member.email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB8C7E8),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${member.teamRole} • ${member.profileLabel}',
                    style: const TextStyle(
                      color: Color(0xFF8FBEFF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            StatusPill(label: member.status.label, color: color),
            PopupMenuButton<String>(
              tooltip: 'Ações do usuário',
              onSelected: (action) => _handleMemberAction(member, action),
              itemBuilder: (context) =>
                  member.status == TeamMemberStatus.inactive
                  ? const [
                      PopupMenuItem(
                        value: 'activate',
                        child: Text('Reativar na equipe'),
                      ),
                    ]
                  : [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(
                        value: member.status == TeamMemberStatus.active
                            ? 'block'
                            : 'activate',
                        child: Text(
                          member.status == TeamMemberStatus.active
                              ? 'Bloquear'
                              : 'Ativar',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'disable',
                        child: Text('Desativar'),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _invitationCard(TeamInvitationSummary invitation) {
    final remaining = invitation.expiresAt.difference(DateTime.now()).inHours;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.outgoing_mail, color: Color(0xFFFFB14D)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invitation.email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Expira em ${remaining.clamp(0, 72)} horas',
                    style: const TextStyle(
                      color: Color(0xFFB8C7E8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const StatusPill(label: 'Pendente', color: Color(0xFFFFB14D)),
          ],
        ),
      ),
    );
  }

  Widget _teamCard(OrganizationTeam team) {
    final active = team.status == TeamStatus.active;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: active
                      ? StudyAppColors.accent
                      : StudyAppColors.textSecondary,
                  child: const Icon(Icons.groups_outlined, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        team.description,
                        style: const TextStyle(
                          color: Color(0xFFB8C7E8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  label: team.status.label,
                  color: active
                      ? const Color(0xFF70F0A4)
                      : const Color(0xFFFF7C8B),
                ),
              ],
            ),
            const Divider(height: 22, color: Color(0xFF1B4A97)),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _teamInfo(Icons.admin_panel_settings_outlined, team.adminName),
                _teamInfo(Icons.people_outline, '${team.memberCount} membros'),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openTeamForm(team),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
                OutlinedButton.icon(
                  onPressed: widget.viewModel.isBusy
                      ? null
                      : () => _changeTeamStatus(team),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: active
                        ? const Color(0xFFFFA7B1)
                        : const Color(0xFF70F0A4),
                  ),
                  icon: Icon(
                    active ? Icons.block_outlined : Icons.refresh_outlined,
                    size: 18,
                  ),
                  label: Text(active ? 'Desativar' : 'Reativar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamInfo(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF8FBEFF), size: 17),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFD9E5FF)),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeading(String title, String trailing) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            color: Color(0xFF60A5FA),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  InputDecoration _darkInput(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9EB3E0)),
      filled: true,
      fillColor: const Color(0xFF0A2860),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1B4A97)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF60A5FA)),
      ),
    );
  }

  Future<void> _openTeamForm([OrganizationTeam? team]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            OrganizationTeamFormView(viewModel: widget.viewModel, team: team),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _changeTeamStatus(OrganizationTeam team) async {
    final nextStatus = team.status == TeamStatus.active
        ? TeamStatus.inactive
        : TeamStatus.active;
    await widget.viewModel.setTeamStatus(team, nextStatus);
    if (mounted) {
      showPrototypeMessage(
        context,
        nextStatus == TeamStatus.active
            ? 'Equipe reativada.'
            : 'Equipe desativada sem remover seus vínculos.',
      );
      setState(() {});
    }
  }

  Future<void> _handleMemberAction(
    OrganizationMember member,
    String action,
  ) async {
    try {
      switch (action) {
        case 'edit':
          await _editMember(member);
        case 'block':
          await widget.viewModel.setTeamUserStatus(
            member,
            TeamMemberStatus.blocked,
          );
        case 'activate':
          await widget.viewModel.setTeamUserStatus(
            member,
            TeamMemberStatus.active,
          );
        case 'disable':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Desativar usuário'),
              content: Text(
                'Desativar ${member.fullName}? O histórico será preservado.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Desativar'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await widget.viewModel.disableTeamUser(member);
          }
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) showPrototypeMessage(context, error.toString());
    }
  }

  Future<void> _editMember(OrganizationMember member) async {
    final nameParts = member.fullName.trim().split(RegExp(r'\s+'));
    final firstName = TextEditingController(
      text: member.firstName.isEmpty ? nameParts.first : member.firstName,
    );
    final lastName = TextEditingController(
      text: member.lastName ?? nameParts.skip(1).join(' '),
    );
    var teamId = member.teamId;
    var teamRole = member.teamRole;
    final profiles = member.profiles.isEmpty
        ? member.profileLabel.split(' • ').toSet()
        : {...member.profiles};
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar usuário'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstName,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: lastName,
                    decoration: const InputDecoration(labelText: 'Sobrenome'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: teamId,
                    decoration: const InputDecoration(labelText: 'Equipe'),
                    items: widget.viewModel.data.teams
                        .map(
                          (team) => DropdownMenuItem(
                            value: team.id,
                            child: Text(team.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => teamId = value ?? teamId),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: teamRole,
                    decoration: const InputDecoration(
                      labelText: 'Papel na equipe',
                    ),
                    items: const ['MEMBRO', 'RESPONSAVEL', 'APROVADOR']
                        .map(
                          (role) =>
                              DropdownMenuItem(value: role, child: Text(role)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => teamRole = value ?? teamRole),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children:
                        const [
                          'MEMBRO_EQUIPE',
                          'APROVADOR_EQUIPE',
                          'ADMIN_EQUIPE',
                          'AUDITOR',
                        ].map((profile) {
                          return FilterChip(
                            label: Text(profile),
                            selected: profiles.contains(profile),
                            onSelected: (selected) => setDialogState(() {
                              if (selected) {
                                profiles.add(profile);
                              } else if (profiles.length > 1) {
                                profiles.remove(profile);
                              }
                            }),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && firstName.text.trim().isNotEmpty) {
      await widget.viewModel.updateTeamUser(
        UpdateOrganizationMemberInput(
          userId: member.id,
          teamId: teamId,
          firstName: firstName.text.trim(),
          lastName: lastName.text.trim().isEmpty ? null : lastName.text.trim(),
          teamRole: teamRole,
          profiles: profiles,
        ),
      );
    }
    firstName.dispose();
    lastName.dispose();
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    return '${parts.first.characters.first}${parts.length > 1 ? parts.last.characters.first : ''}'
        .toUpperCase();
  }
}
