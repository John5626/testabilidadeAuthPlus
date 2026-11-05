import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../home/domain/app_status.dart';
import '../domain/managed_user.dart';
import 'user_management_view_model.dart';

class UserManagementView extends StatelessWidget {
  const UserManagementView({
    required this.dependencies,
    required this.status,
    this.onOpenPublicRegistration,
    super.key,
  });

  final AppDependencies dependencies;
  final AppStatus status;
  final VoidCallback? onOpenPublicRegistration;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<UserManagementViewModel>(
      create: () => UserManagementViewModel(
        repository: dependencies.userManagementRepository,
      ),
      builder: (context, viewModel, child) {
        return _UserManagementContent(
          status: status,
          viewModel: viewModel,
          onOpenPublicRegistration: onOpenPublicRegistration,
        );
      },
    );
  }
}

class _UserManagementContent extends StatefulWidget {
  const _UserManagementContent({
    required this.status,
    required this.viewModel,
    required this.onOpenPublicRegistration,
  });

  final AppStatus status;
  final UserManagementViewModel viewModel;
  final VoidCallback? onOpenPublicRegistration;

  @override
  State<_UserManagementContent> createState() => _UserManagementContentState();
}

class _UserManagementContentState extends State<_UserManagementContent> {
  final _contextFormKey = GlobalKey<FormState>();
  final _organizationController = TextEditingController();
  final _teamController = TextEditingController();
  final _actorController = TextEditingController();
  bool _filterByTeam = true;

  UserManagementContext get _managementContext {
    return UserManagementContext(
      organizationId: _organizationController.text,
      teamId: _teamController.text,
      actorUserId: _actorController.text,
    );
  }

  @override
  void initState() {
    super.initState();
    _organizationController.addListener(_handleContextChanged);
    _teamController.addListener(_handleContextChanged);
    _actorController.addListener(_handleContextChanged);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 920;
    final content = wide ? _buildWideLayout() : _buildMobileLayout();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [StudyAppColors.navyDeep, StudyAppColors.navy],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  wide ? 32 : 16,
                  18,
                  wide ? 32 : 16,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      status: widget.status,
                      onOpenPublicRegistration: widget.onOpenPublicRegistration,
                    ),
                    const SizedBox(height: 18),
                    content,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ContextPanel(
          formKey: _contextFormKey,
          organizationController: _organizationController,
          teamController: _teamController,
          actorController: _actorController,
          filterByTeam: _filterByTeam,
          isBusy: widget.viewModel.isBusy,
          onFilterChanged: (value) => setState(() => _filterByTeam = value),
          onLoad: _loadUsers,
        ),
        const SizedBox(height: 16),
        _MessagesPanel(viewModel: widget.viewModel),
        const SizedBox(height: 16),
        _UserFormPanel(
          viewModel: widget.viewModel,
          managementContext: _managementContext,
        ),
        const SizedBox(height: 16),
        _InvitationTokenPanel(viewModel: widget.viewModel),
        const SizedBox(height: 16),
        _UsersPanel(
          viewModel: widget.viewModel,
          managementContext: _managementContext,
        ),
        const SizedBox(height: 16),
        _CompleteInvitationPanel(viewModel: widget.viewModel),
        const SizedBox(height: 16),
        _EnvironmentPanel(status: widget.status),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 340,
          child: Column(
            children: [
              _ContextPanel(
                formKey: _contextFormKey,
                organizationController: _organizationController,
                teamController: _teamController,
                actorController: _actorController,
                filterByTeam: _filterByTeam,
                isBusy: widget.viewModel.isBusy,
                onFilterChanged: (value) =>
                    setState(() => _filterByTeam = value),
                onLoad: _loadUsers,
              ),
              const SizedBox(height: 16),
              _CompleteInvitationPanel(viewModel: widget.viewModel),
              const SizedBox(height: 16),
              _EnvironmentPanel(status: widget.status),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              _MessagesPanel(viewModel: widget.viewModel),
              const SizedBox(height: 16),
              _UserFormPanel(
                viewModel: widget.viewModel,
                managementContext: _managementContext,
              ),
              const SizedBox(height: 16),
              _InvitationTokenPanel(viewModel: widget.viewModel),
              const SizedBox(height: 16),
              _UsersPanel(
                viewModel: widget.viewModel,
                managementContext: _managementContext,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _loadUsers() {
    if (!(_contextFormKey.currentState?.validate() ?? false)) {
      return;
    }

    widget.viewModel.loadUsers(
      _managementContext,
      teamId: _filterByTeam ? _teamController.text.trim() : null,
    );
  }

  void _handleContextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _organizationController.dispose();
    _teamController.dispose();
    _actorController.dispose();
    super.dispose();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.status, required this.onOpenPublicRegistration});

  final AppStatus status;
  final VoidCallback? onOpenPublicRegistration;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo/icon.png',
          width: 58,
          height: 58,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.lock, size: 48, color: Colors.white);
          },
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'StudyApp',
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Segurança, controle e auditoria',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
        if (onOpenPublicRegistration != null)
          OutlinedButton.icon(
            onPressed: onOpenPublicRegistration,
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Cadastro'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.46)),
            ),
          )
        else
          _EnvironmentBadge(label: status.environmentLabel),
      ],
    );
  }
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({
    required this.formKey,
    required this.organizationController,
    required this.teamController,
    required this.actorController,
    required this.filterByTeam,
    required this.isBusy,
    required this.onFilterChanged,
    required this.onLoad,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController organizationController;
  final TextEditingController teamController;
  final TextEditingController actorController;
  final bool filterByTeam;
  final bool isBusy;
  final ValueChanged<bool> onFilterChanged;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Contexto administrativo',
      subtitle:
          'Use os identificadores exigidos pela US03 ate o login existir.',
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              controller: organizationController,
              decoration: const InputDecoration(
                labelText: 'Organização',
                hintText: 'UUID da organização',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: _validateUuid,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: teamController,
              decoration: const InputDecoration(
                labelText: 'Equipe',
                hintText: 'UUID da equipe',
                prefixIcon: Icon(Icons.groups_2_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: _validateUuid,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: actorController,
              decoration: const InputDecoration(
                labelText: 'Usuário ator',
                hintText: 'UUID do Admin equipe ativo',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
              textInputAction: TextInputAction.done,
              validator: _validateUuid,
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Listar somente esta equipe'),
              subtitle: const Text(
                'Remova o filtro para ver toda a organização.',
              ),
              value: filterByTeam,
              onChanged: onFilterChanged,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isBusy ? null : onLoad,
                icon: const Icon(Icons.sync),
                label: const Text('Carregar usuários'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesPanel extends StatelessWidget {
  const _MessagesPanel({required this.viewModel});

  final UserManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final message = viewModel.errorMessage ?? viewModel.message;
    if (message == null) {
      return const SizedBox.shrink();
    }

    final isError = viewModel.errorMessage != null;
    final color = isError ? StudyAppColors.danger : StudyAppColors.success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StudyAppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: viewModel.clearMessages,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _UserFormPanel extends StatefulWidget {
  const _UserFormPanel({
    required this.viewModel,
    required this.managementContext,
  });

  final UserManagementViewModel viewModel;
  final UserManagementContext managementContext;

  @override
  State<_UserFormPanel> createState() => _UserFormPanelState();
}

class _UserFormPanelState extends State<_UserFormPanel> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _teamController = TextEditingController();
  String? _hydratedUserId;
  TeamRole _role = TeamRole.membro;
  Set<AccessProfile> _profiles = {AccessProfile.membroEquipe};

  @override
  void initState() {
    super.initState();
    _teamController.text = widget.managementContext.teamId.trim();
  }

  @override
  void didUpdateWidget(covariant _UserFormPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final editing = widget.viewModel.editingUser;
    if (editing?.id == _hydratedUserId) {
      if (editing == null &&
          _teamController.text.isEmpty &&
          widget.managementContext.teamId.trim().isNotEmpty) {
        _teamController.text = widget.managementContext.teamId.trim();
      }
      return;
    }

    if (editing == null) {
      _hydratedUserId = null;
      _resetCreateForm(keepTeam: true);
      return;
    }

    _hydratedUserId = editing.id;
    _nameController.text = editing.displayName;
    _emailController.text = editing.email;
    _teamController.text = editing.teamId;
    _role = editing.teamRole;
    _profiles = editing.profiles.isEmpty
        ? {AccessProfile.membroEquipe}
        : editing.profiles;
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.viewModel.editingUser;
    final isEditing = editing != null;

    return _Panel(
      title: isEditing ? 'Editar usuário' : 'Novo usuário',
      subtitle: isEditing
          ? 'Atualize papel e perfis dentro da alçada do Admin equipe.'
          : 'Cadastre um usuário pendente e gere o convite de senha.',
      trailing: isEditing
          ? TextButton.icon(
              onPressed: widget.viewModel.isBusy
                  ? null
                  : () {
                      widget.viewModel.cancelEdit();
                      _resetCreateForm(keepTeam: true);
                    },
              icon: const Icon(Icons.close),
              label: const Text('Cancelar'),
            )
          : null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Informe o nome.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              enabled: !isEditing,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (isEditing) {
                  return null;
                }
                final email = (value ?? '').trim();
                if (email.isEmpty || !email.contains('@')) {
                  return 'Informe um e-mail valido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _teamController,
              decoration: const InputDecoration(
                labelText: 'Equipe vinculada',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: _validateUuid,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TeamRole>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Papel na equipe',
                prefixIcon: Icon(Icons.assignment_ind_outlined),
              ),
              items: TeamRole.values
                  .map(
                    (role) => DropdownMenuItem<TeamRole>(
                      value: role,
                      child: Text(role.label),
                    ),
                  )
                  .toList(),
              onChanged: widget.viewModel.isBusy
                  ? null
                  : (role) => setState(() => _role = role ?? TeamRole.membro),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Perfis atribuiveis',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AccessProfile.values
                  .where((profile) => profile.assignableByTeamAdmin)
                  .map((profile) {
                    final selected = _profiles.contains(profile);
                    return FilterChip(
                      selected: selected,
                      label: Text(profile.label),
                      avatar: Icon(_profileIcon(profile), size: 18),
                      onSelected: widget.viewModel.isBusy
                          ? null
                          : (value) => _toggleProfile(profile, value),
                    );
                  })
                  .toList(),
            ),
            if (_profiles.isEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Selecione ao menos um perfil.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            if (!isEditing) ...[
              const SizedBox(height: 12),
              const Text(
                'O consentimento de dados pessoais será confirmado pelo próprio convidado ao concluir o convite.',
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.viewModel.isBusy ? null : _submit,
              icon: Icon(
                isEditing ? Icons.save_outlined : Icons.person_add_alt,
              ),
              label: Text(
                isEditing ? 'Salvar alterações' : 'Cadastrar usuário',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_profiles.isEmpty) {
      setState(() {});
      return;
    }

    final isEditing = widget.viewModel.editingUser != null;
    await widget.viewModel.saveUser(
      widget.managementContext,
      createInput: CreateManagedUserInput(
        teamId: _teamController.text,
        email: _emailController.text,
        displayName: _nameController.text,
        teamRole: _role,
        profiles: _profiles,
      ),
      updateInput: UpdateManagedUserInput(
        teamId: _teamController.text,
        displayName: _nameController.text,
        teamRole: _role,
        profiles: _profiles,
      ),
    );

    if (!mounted || widget.viewModel.errorMessage != null) {
      return;
    }

    if (!isEditing) {
      _resetCreateForm(keepTeam: true);
    }
  }

  void _toggleProfile(AccessProfile profile, bool selected) {
    setState(() {
      final next = {..._profiles};
      if (selected) {
        next.add(profile);
      } else {
        next.remove(profile);
      }
      _profiles = next;
    });
  }

  void _resetCreateForm({required bool keepTeam}) {
    final team = keepTeam
        ? (_teamController.text.isNotEmpty
              ? _teamController.text
              : widget.managementContext.teamId.trim())
        : widget.managementContext.teamId.trim();
    _nameController.clear();
    _emailController.clear();
    _teamController.text = team;
    _role = TeamRole.membro;
    _profiles = {AccessProfile.membroEquipe};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _teamController.dispose();
    super.dispose();
  }
}

class _InvitationTokenPanel extends StatelessWidget {
  const _InvitationTokenPanel({required this.viewModel});

  final UserManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final createdUser = viewModel.latestCreatedUser;
    final invitation = createdUser?.invitation;
    if (createdUser == null || invitation == null) {
      return const SizedBox.shrink();
    }

    return _Panel(
      title: 'Convite gerado',
      subtitle: 'O token aparece somente neste retorno transacional.',
      trailing: IconButton(
        tooltip: 'Ocultar token',
        onPressed: viewModel.dismissInvitationToken,
        icon: const Icon(Icons.visibility_off_outlined),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoLine(icon: Icons.person_outline, text: createdUser.email),
          const SizedBox(height: 8),
          _InfoLine(
            icon: Icons.timer_outlined,
            text: 'Expira em ${_formatDateTime(invitation.expiresAt)}',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StudyAppColors.surfaceTint,
              borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                invitation.token,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Copie e envie por canal seguro. O app não armazena este token.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: StudyAppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: invitation.token));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token copiado.')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsersPanel extends StatelessWidget {
  const _UsersPanel({required this.viewModel, required this.managementContext});

  final UserManagementViewModel viewModel;
  final UserManagementContext managementContext;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Usuários da equipe',
      subtitle: 'Acompanhe status, aceite de termos, papel e perfis.',
      trailing: IconButton(
        tooltip: 'Atualizar',
        onPressed: viewModel.isBusy ? null : viewModel.refreshLastQuery,
        icon: const Icon(Icons.refresh),
      ),
      child: Column(
        children: [
          _StatsGrid(viewModel: viewModel),
          const SizedBox(height: 16),
          if (viewModel.state == UserManagementState.loading &&
              viewModel.users.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else if (viewModel.users.isEmpty)
            const _EmptyUsersState()
          else
            Column(
              children: viewModel.users
                  .map(
                    (user) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _UserCard(
                        user: user,
                        isBusy: viewModel.isBusy,
                        onEdit: () => viewModel.startEdit(user),
                        onBlock: () => viewModel.changeStatus(
                          managementContext,
                          user,
                          UserStatus.blocked,
                        ),
                        onActivate: () => viewModel.changeStatus(
                          managementContext,
                          user,
                          UserStatus.active,
                        ),
                        onDisable: () =>
                            viewModel.disableUser(managementContext, user),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.viewModel});

  final UserManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatTile(
          label: 'Pendentes',
          value: viewModel.pendingCount.toString(),
          icon: Icons.hourglass_top,
          color: StudyAppColors.warning,
        ),
        _StatTile(
          label: 'Ativos',
          value: viewModel.activeCount.toString(),
          icon: Icons.check_circle_outline,
          color: StudyAppColors.success,
        ),
        _StatTile(
          label: 'Bloqueados',
          value: viewModel.blockedCount.toString(),
          icon: Icons.block,
          color: StudyAppColors.danger,
        ),
        _StatTile(
          label: 'Desativados',
          value: viewModel.disabledCount.toString(),
          icon: Icons.person_off_outlined,
          color: StudyAppColors.textSecondary,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: StudyAppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isBusy,
    required this.onEdit,
    required this.onBlock,
    required this.onActivate,
    required this.onDisable,
  });

  final ManagedUser user;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onBlock;
  final VoidCallback onActivate;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    final canEdit = user.status != UserStatus.disabled;
    final canActivate =
        user.status == UserStatus.blocked && !user.termsAcceptanceRequired;
    final canBlock =
        user.status != UserStatus.blocked && user.status != UserStatus.disabled;
    final canDisable = user.status != UserStatus.disabled;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudyAppColors.background,
        borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
        border: Border.all(color: StudyAppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: StudyAppColors.accent.withValues(alpha: 0.12),
                child: Text(
                  _initials(user.displayName),
                  style: const TextStyle(
                    color: StudyAppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: StudyAppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: user.status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(icon: Icons.groups_outlined, label: user.teamName),
              _Tag(
                icon: Icons.assignment_ind_outlined,
                label: user.teamRole.label,
              ),
              _Tag(
                icon: Icons.fact_check_outlined,
                label: user.termsAcceptanceRequired
                    ? 'Aceite pendente'
                    : 'Termos aceitos',
              ),
              ...user.profiles.map(
                (profile) =>
                    _Tag(icon: _profileIcon(profile), label: profile.label),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: isBusy || !canEdit ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
              if (canActivate)
                FilledButton.icon(
                  onPressed: isBusy ? null : onActivate,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Ativar'),
                ),
              if (canBlock)
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onBlock,
                  icon: const Icon(Icons.block),
                  label: const Text('Bloquear'),
                ),
              if (canDisable)
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onDisable,
                  icon: const Icon(Icons.person_off_outlined),
                  label: const Text('Desativar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompleteInvitationPanel extends StatefulWidget {
  const _CompleteInvitationPanel({required this.viewModel});

  final UserManagementViewModel viewModel;

  @override
  State<_CompleteInvitationPanel> createState() =>
      _CompleteInvitationPanelState();
}

class _CompleteInvitationPanelState extends State<_CompleteInvitationPanel> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _personalDataConsentAccepted = false;

  @override
  Widget build(BuildContext context) {
    final completed = widget.viewModel.completedInvitationUser;

    return _Panel(
      title: 'Concluir convite',
      subtitle: 'Definição de senha sem sessão autenticada.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Token do convite',
                prefixIcon: Icon(Icons.key_outlined),
              ),
              minLines: 1,
              maxLines: 3,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Informe o token.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Nova senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                final password = value ?? '';
                if (password.runes.length < 12) {
                  return 'Use ao menos 12 caracteres.';
                }
                if (password.runes.length > 128) {
                  return 'Use no maximo 128 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordConfirmationController,
              decoration: const InputDecoration(
                labelText: 'Confirmação da senha',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              obscureText: true,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'A confirmação deve ser igual à senha.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _personalDataConsentAccepted,
              onChanged: widget.viewModel.isBusy
                  ? null
                  : (value) => setState(() {
                      _personalDataConsentAccepted = value ?? false;
                    }),
              title: const Text('Consentimento de dados pessoais'),
              subtitle: const Text(
                'Confirmo, como usuário convidado, o tratamento necessário dos meus dados para criação do acesso.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: widget.viewModel.isBusy ? null : _submit,
              icon: const Icon(Icons.check),
              label: const Text('Concluir convite'),
            ),
            if (completed != null) ...[
              const SizedBox(height: 12),
              _InfoLine(
                icon: Icons.check_circle_outline,
                text: '${completed.displayName} permanece pendente de termos.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await widget.viewModel.completeInvitation(
      token: _tokenController.text,
      password: _passwordController.text,
      passwordConfirmation: _passwordConfirmationController.text,
      personalDataConsentAccepted: _personalDataConsentAccepted,
    );

    if (!mounted || widget.viewModel.errorMessage != null) {
      return;
    }

    _tokenController.clear();
    _passwordController.clear();
    _passwordConfirmationController.clear();
    setState(() => _personalDataConsentAccepted = false);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }
}

class _EnvironmentPanel extends StatelessWidget {
  const _EnvironmentPanel({required this.status});

  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Ambiente',
      subtitle: 'Configuração carregada no app.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(icon: Icons.tune, text: status.environmentLabel),
          const SizedBox(height: 8),
          _InfoLine(
            icon: Icons.cloud_outlined,
            text: status.apiBaseUrl.toString(),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyAppColors.surface,
        borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
        border: Border.all(color: StudyAppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: StudyAppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: StudyAppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: StudyAppColors.accent),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: StudyAppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: StudyAppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EnvironmentBadge extends StatelessWidget {
  const _EnvironmentBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyUsersState extends StatelessWidget {
  const _EmptyUsersState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          Icon(
            Icons.group_add_outlined,
            size: 44,
            color: StudyAppColors.textMuted.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 10),
          Text(
            'Nenhum usuário carregado.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Informe o contexto administrativo e carregue a lista.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: StudyAppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String? _validateUuid(String? value) {
  final input = (value ?? '').trim();
  if (input.isEmpty) {
    return 'Informe o UUID.';
  }

  final uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  if (!uuid.hasMatch(input)) {
    return 'Use um UUID valido.';
  }

  return null;
}

IconData _profileIcon(AccessProfile profile) {
  return switch (profile) {
    AccessProfile.adminSistema => Icons.security_outlined,
    AccessProfile.adminOrganizacao => Icons.domain_outlined,
    AccessProfile.adminEquipe => Icons.admin_panel_settings_outlined,
    AccessProfile.auditor => Icons.manage_search_outlined,
    AccessProfile.aprovadorEquipe => Icons.fact_check_outlined,
    AccessProfile.membroEquipe => Icons.person_outline,
  };
}

Color _statusColor(UserStatus status) {
  return switch (status) {
    UserStatus.pending => StudyAppColors.warning,
    UserStatus.active => StudyAppColors.success,
    UserStatus.blocked => StudyAppColors.danger,
    UserStatus.disabled => StudyAppColors.textSecondary,
  };
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '?';
  }

  final first = _firstRune(parts.first);
  final second = parts.length > 1 ? _firstRune(parts.last) : '';
  return '$first$second'.toUpperCase();
}

String _firstRune(String value) {
  if (value.isEmpty) {
    return '';
  }

  return String.fromCharCode(value.runes.first);
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
