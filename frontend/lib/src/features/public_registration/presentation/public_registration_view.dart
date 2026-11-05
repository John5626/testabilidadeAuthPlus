import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../home/domain/app_status.dart';
import '../domain/organization_registration.dart';
import 'public_registration_view_model.dart';

class PublicRegistrationView extends StatelessWidget {
  const PublicRegistrationView({
    required this.dependencies,
    required this.status,
    this.onOpenUserManagement,
    super.key,
  });

  final AppDependencies dependencies;
  final AppStatus status;
  final VoidCallback? onOpenUserManagement;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PublicRegistrationViewModel>(
      create: () => PublicRegistrationViewModel(
        repository: dependencies.publicRegistrationRepository,
      ),
      builder: (context, viewModel, child) {
        return _PublicRegistrationContent(
          status: status,
          viewModel: viewModel,
          onOpenUserManagement: onOpenUserManagement,
        );
      },
    );
  }
}

class _PublicRegistrationContent extends StatelessWidget {
  const _PublicRegistrationContent({
    required this.status,
    required this.viewModel,
    required this.onOpenUserManagement,
  });

  final AppStatus status;
  final PublicRegistrationViewModel viewModel;
  final VoidCallback? onOpenUserManagement;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;

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
              constraints: const BoxConstraints(maxWidth: 1080),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  wide ? 32 : 18,
                  24,
                  wide ? 32 : 18,
                  32,
                ),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _BrandColumn(
                              status: status,
                              onOpenUserManagement: onOpenUserManagement,
                            ),
                          ),
                          const SizedBox(width: 36),
                          SizedBox(
                            width: 430,
                            child: _RegistrationCard(viewModel: viewModel),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BrandColumn(
                            status: status,
                            onOpenUserManagement: onOpenUserManagement,
                          ),
                          const SizedBox(height: 24),
                          _RegistrationCard(viewModel: viewModel),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandColumn extends StatelessWidget {
  const _BrandColumn({
    required this.status,
    required this.onOpenUserManagement,
  });

  final AppStatus status;
  final VoidCallback? onOpenUserManagement;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/logo/icon.png',
              width: 64,
              height: 64,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.lock, size: 54, color: Colors.white);
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
                  Text(
                    'Segurança, controle e auditoria',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            _EnvironmentBadge(label: status.environmentLabel),
          ],
        ),
        const SizedBox(height: 34),
        Text(
          'Criar conta administrativa',
          style: textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Cadastre a organização, a equipe inicial e o Admin organização para iniciar o ambiente institucional.',
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.82),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _SecurityPill(
              icon: Icons.verified_user_outlined,
              label: 'Consentimento',
            ),
            _SecurityPill(
              icon: Icons.groups_2_outlined,
              label: 'Equipe inicial',
            ),
            _SecurityPill(
              icon: Icons.fact_check_outlined,
              label: 'Aceite pendente',
            ),
          ],
        ),
        if (onOpenUserManagement != null) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onOpenUserManagement,
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('Gestão de usuários'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.46)),
            ),
          ),
        ],
      ],
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.viewModel});

  final PublicRegistrationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final result = viewModel.registration;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StudyAppColors.surface,
        borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
        border: Border.all(color: StudyAppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result == null)
            _RegistrationForm(viewModel: viewModel)
          else
            _RegistrationResult(registration: result),
        ],
      ),
    );
  }
}

class _RegistrationForm extends StatefulWidget {
  const _RegistrationForm({required this.viewModel});

  final PublicRegistrationViewModel viewModel;

  @override
  State<_RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<_RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _organizationController = TextEditingController();
  final _domainController = TextEditingController();
  final _teamController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _consentAccepted = false;
  bool _showConsentError = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Dados da conta',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'O Admin organização nasce pendente do aceite versionado de termos e políticas antes do acesso pleno.',
            style: textTheme.bodyMedium?.copyWith(
              color: StudyAppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          _MessageBox(viewModel: widget.viewModel),
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'Nome',
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
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Sobrenome',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Informe o sobrenome.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-mail institucional',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final email = (value ?? '').trim();
              if (email.isEmpty || !email.contains('@')) {
                return 'Informe um e-mail valido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _organizationController,
            decoration: const InputDecoration(
              labelText: 'Empresa/Organização',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Informe a organização.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _domainController,
            decoration: const InputDecoration(
              labelText: 'Domínio da organização',
              hintText: 'exemplo.edu.br',
              prefixIcon: Icon(Icons.language_outlined),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _teamController,
            decoration: const InputDecoration(
              labelText: 'Equipe inicial',
              prefixIcon: Icon(Icons.groups_2_outlined),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Informe a equipe inicial.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
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
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirmar senha',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                tooltip: _obscureConfirmation
                    ? 'Mostrar senha'
                    : 'Ocultar senha',
                onPressed: () {
                  setState(() => _obscureConfirmation = !_obscureConfirmation);
                },
                icon: Icon(
                  _obscureConfirmation
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            obscureText: _obscureConfirmation,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'As senhas devem ser iguais.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consentAccepted,
            onChanged: widget.viewModel.isSubmitting
                ? null
                : (value) => setState(() {
                    _consentAccepted = value ?? false;
                    _showConsentError = false;
                  }),
            title: const Text('Autorizo o tratamento dos meus dados pessoais.'),
            subtitle: const Text(
              'Seu consentimento será registrado. As versões vigentes dos termos e políticas deverão ser aceitas no primeiro acesso.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_showConsentError)
            Text(
              'O consentimento explicito é obrigatório.',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: widget.viewModel.isSubmitting ? null : _submit,
            icon: widget.viewModel.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt),
            label: const Text('Criar conta'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.apartment_outlined),
            label: const Text('Conta institucional (SSO)'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_consentAccepted) {
      setState(() => _showConsentError = true);
      return;
    }

    await widget.viewModel.register(
      RegisterOrganizationAdminInput(
        organizationName: _organizationController.text,
        organizationDomain: _domainController.text,
        teamName: _teamController.text,
        email: _emailController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        personalDataConsentAccepted: _consentAccepted,
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _organizationController.dispose();
    _domainController.dispose();
    _teamController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.viewModel});

  final PublicRegistrationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final message = viewModel.errorMessage;
    if (message == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: StudyAppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
          border: Border.all(
            color: StudyAppColors.danger.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: StudyAppColors.danger),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            IconButton(
              tooltip: 'Fechar',
              onPressed: viewModel.clearError,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationResult extends StatelessWidget {
  const _RegistrationResult({required this.registration});

  final OrganizationAdminRegistration registration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: StudyAppColors.success,
          size: 52,
        ),
        const SizedBox(height: 14),
        Text(
          'Conta administrativa criada',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'O Admin organização permanece pendente do aceite versionado de termos e políticas antes do acesso pleno.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: StudyAppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        _ResultLine(label: 'Organização', value: registration.organizationName),
        _ResultLine(
          label: 'ID da organização',
          value: registration.organizationId,
        ),
        _ResultLine(label: 'Equipe', value: registration.teamName),
        _ResultLine(label: 'ID da equipe', value: registration.teamId),
        _ResultLine(label: 'Admin', value: registration.admin.displayName),
        _ResultLine(label: 'ID admin', value: registration.admin.id),
        _ResultLine(label: 'Status', value: registration.admin.status),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () {
            final summary = [
              'organizationId=${registration.organizationId}',
              'teamId=${registration.teamId}',
              'adminId=${registration.admin.id}',
            ].join('\n');
            Clipboard.setData(ClipboardData(text: summary));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('IDs copiados.')));
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copiar IDs'),
        ),
      ],
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudyAppColors.background,
        borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
        border: Border.all(color: StudyAppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: StudyAppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SecurityPill extends StatelessWidget {
  const _SecurityPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: StudyAppColors.accentSoft),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
