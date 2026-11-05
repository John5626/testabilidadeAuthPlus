import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/studyapp_models.dart';
import '../domain/password_policy.dart';
import 'widgets/studyapp_ui.dart';
import 'widgets/password_requirements.dart';
import 'widgets/safe_policy_html.dart';

class AcceptTeamInvitationView extends StatefulWidget {
  const AcceptTeamInvitationView({
    required this.isBusy,
    required this.errorMessage,
    required this.preview,
    required this.acceptance,
    this.initialToken,
    required this.onBack,
    required this.onValidate,
    required this.onAccept,
    required this.onGoToLogin,
    this.webInvitationFlow = false,
    this.onInvitationAccepted,
    super.key,
  });

  final bool isBusy;
  final String? errorMessage;
  final TeamInvitationPreview? preview;
  final TeamInvitationAcceptance? acceptance;
  final String? initialToken;
  final VoidCallback onBack;
  final Future<bool> Function(String token) onValidate;
  final Future<bool> Function(AcceptTeamInvitationInput input) onAccept;
  final VoidCallback onGoToLogin;
  final bool webInvitationFlow;
  final Future<void> Function()? onInvitationAccepted;

  @override
  State<AcceptTeamInvitationView> createState() =>
      _AcceptTeamInvitationViewState();
}

class _AcceptTeamInvitationViewState extends State<AcceptTeamInvitationView> {
  final _tokenFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  int _step = 0;
  bool _obscureToken = true;
  bool _obscurePassword = true;
  bool _personalDataConsentAccepted = false;
  bool _showAcceptanceErrors = false;
  int _policyIndex = 0;
  final Set<String> _acceptedPolicyIds = {};

  @override
  void initState() {
    super.initState();
    final initialToken = widget.initialToken;
    if (initialToken != null && initialToken.isNotEmpty) {
      _token.text = initialToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _validateInvitation();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: ContentWidth(
        maxWidth: 680,
        child: Column(
          children: [
            AppTopBar(onBack: _handleBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                child: widget.acceptance == null
                    ? _buildFlow(context)
                    : _buildSuccess(context, widget.acceptance!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          'Aceitar convite',
          subtitle:
              'Confirme o vínculo recebido e proteja sua conta antes de entrar na equipe.',
        ),
        const SizedBox(height: 18),
        _ProgressHeader(step: _step),
        const SizedBox(height: 16),
        GlassCard(
          color: Colors.white,
          padding: const EdgeInsets.all(22),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_step) {
              0 => _buildTokenStep(),
              1 => _buildPoliciesStep(),
              2 => _buildAccountStep(),
              _ => _buildReviewStep(),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPoliciesStep() {
    final preview = widget.preview!;
    if (preview.policies.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _step == 1) setState(() => _step = 2);
      });
      return const Center(child: CircularProgressIndicator());
    }
    final policy = preview.policies[_policyIndex];
    final accepted = _acceptedPolicyIds.contains(policy.policyVersionId);
    return Column(
      key: const ValueKey('invitation-policy-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepTitle(
          icon: Icons.policy_outlined,
          title: policy.title,
          subtitle:
              'Documento ${_policyIndex + 1} de ${preview.policies.length} • versão ${policy.version}',
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (_policyIndex + 1) / preview.policies.length,
          minHeight: 7,
        ),
        const SizedBox(height: 14),
        Container(
          constraints: const BoxConstraints(maxHeight: 380),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFD8E0EF)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            child: SafePolicyHtml(html: policy.content),
          ),
        ),
        CheckboxListTile(
          key: const Key('invitation-policy-acceptance'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: accepted,
          onChanged: widget.isBusy
              ? null
              : (value) => setState(() {
                  if (value ?? false) {
                    _acceptedPolicyIds.add(policy.policyVersionId);
                  } else {
                    _acceptedPolicyIds.remove(policy.policyVersionId);
                  }
                }),
          title: const Text('Li e aceito esta versão do documento.'),
        ),
        FilledButton(
          onPressed: !accepted || widget.isBusy
              ? null
              : () => setState(() {
                  if (_policyIndex < preview.policies.length - 1) {
                    _policyIndex++;
                  } else {
                    _step = 2;
                  }
                }),
          child: Text(
            _policyIndex < preview.policies.length - 1
                ? 'Aceitar e avançar'
                : 'Continuar para a conta',
          ),
        ),
      ],
    );
  }

  Widget _buildTokenStep() {
    return Form(
      key: _tokenFormKey,
      child: Column(
        key: const ValueKey('invitation-token-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepTitle(
            icon: Icons.mark_email_read_outlined,
            title: 'Localize seu convite',
            subtitle:
                'O token normalmente chega no link enviado pelo administrador da equipe.',
          ),
          const SizedBox(height: 18),
          TextFormField(
            key: const Key('invitation-token'),
            controller: _token,
            obscureText: _obscureToken,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Token do convite',
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: IconButton(
                tooltip: _obscureToken ? 'Mostrar token' : 'Ocultar token',
                onPressed: () => setState(() => _obscureToken = !_obscureToken),
                icon: Icon(
                  _obscureToken
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'Informe o token recebido.'
                : null,
          ),
          const SizedBox(height: 12),
          const _SecurityNotice(
            text:
                'O StudyApp não grava o token neste dispositivo. Ele será descartado após o uso.',
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorMessage(widget.errorMessage!),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('validate-invitation'),
            onPressed: widget.isBusy ? null : _validateInvitation,
            icon: widget.isBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward),
            label: const Text('Validar convite'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStep() {
    final preview = widget.preview!;
    return Form(
      key: _accountFormKey,
      child: Column(
        key: const ValueKey('invitation-account-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(
            icon: preview.accountExists
                ? Icons.verified_user_outlined
                : Icons.person_add_alt_1_outlined,
            title: preview.accountExists
                ? 'Confirme sua conta'
                : 'Complete sua conta',
            subtitle: preview.accountExists
                ? 'Encontramos uma conta StudyApp para este e-mail. Confirme o novo vínculo sem recriar a conta.'
                : 'Crie sua própria senha. O administrador nunca terá acesso a ela.',
          ),
          const SizedBox(height: 18),
          _InvitationSummaryCard(preview: preview),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: preview.email,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'E-mail convidado',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          if (!preview.accountExists) ...[
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('invitation-password'),
              controller: _password,
              obscureText: _obscurePassword,
              enableSuggestions: false,
              autocorrect: false,
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
              validator: _validatePassword,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('invitation-password-confirmation'),
              controller: _passwordConfirmation,
              obscureText: _obscurePassword,
              decoration: const InputDecoration(
                labelText: 'Confirmar nova senha',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) => value == _password.text
                  ? null
                  : 'As senhas precisam ser iguais.',
            ),
            const SizedBox(height: 10),
            PasswordRequirementsEditor(
              password: _password,
              confirmation: _passwordConfirmation,
              identity: PasswordIdentityInput(
                email: preview.email,
                firstName: preview.fullName.split(' ').first,
                lastName: preview.fullName.split(' ').skip(1).join(' '),
              ),
            ),
          ],
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorMessage(widget.errorMessage!),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('continue-invitation-account'),
            onPressed: widget.isBusy ? null : _continueToReview,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final preview = widget.preview!;
    return Column(
      key: const ValueKey('invitation-review-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepTitle(
          icon: Icons.fact_check_outlined,
          title: 'Revise e aceite',
          subtitle:
              'O vínculo dá acesso somente ao escopo e aos perfis apresentados abaixo.',
        ),
        const SizedBox(height: 18),
        _InvitationSummaryCard(preview: preview, expanded: true),
        const SizedBox(height: 12),
        _SecurityNotice(
          text: preview.policies.isEmpty
              ? 'Não há novos documentos pendentes. Apenas o vínculo com a equipe será confirmado.'
              : 'As versões apresentadas foram lidas neste fluxo e serão registradas ao confirmar o convite.',
        ),
        if (!preview.accountExists)
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              key: const Key('accept-invitation-data-consent'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _personalDataConsentAccepted,
              onChanged: widget.isBusy
                  ? null
                  : (value) => setState(
                      () => _personalDataConsentAccepted = value ?? false,
                    ),
              title: const Text(
                'Confirmo o convite e o tratamento dos meus dados',
              ),
              subtitle: const Text(
                'Seus dados serão usados para identidade, autorização e auditoria no StudyApp.',
              ),
            ),
          ),
        if (!preview.accountExists &&
            _showAcceptanceErrors &&
            !_personalDataConsentAccepted)
          Text(
            'Confirme os itens obrigatórios para aceitar o convite.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 12),
          _ErrorMessage(widget.errorMessage!),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const Key('accept-team-invitation'),
          onPressed: widget.isBusy ? null : _acceptInvitation,
          icon: widget.isBusy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(
            preview.accountExists
                ? 'Aceitar e entrar na equipe'
                : 'Criar conta e aceitar convite',
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(
    BuildContext context,
    TeamInvitationAcceptance acceptance,
  ) {
    return GlassCard(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyAppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: StudyAppColors.success,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Convite aceito!',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            acceptance.accountCreated
                ? 'Sua conta foi criada e agora faz parte da equipe ${acceptance.teamName}.'
                : 'Sua conta agora também faz parte da equipe ${acceptance.teamName}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: StudyAppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          _SecurityNotice(
            text: acceptance.session != null
                ? 'Conta ativada e sessão protegida iniciada. Você já pode entrar na aplicação.'
                : 'O novo vínculo foi ativado. Entre com sua conta existente para acessar a equipe.',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('invitation-go-to-login'),
            onPressed: _continueAfterAcceptance,
            icon: Icon(
              acceptance.session != null ? Icons.login : Icons.lock_open,
            ),
            label: Text(
              acceptance.session != null
                  ? 'Entrar na aplicação'
                  : 'Ir para o login',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _validateInvitation() async {
    if (!(_tokenFormKey.currentState?.validate() ?? false)) return;
    final success = await widget.onValidate(_token.text.trim());
    if (success && mounted) setState(() => _step = 1);
  }

  void _continueToReview() {
    if (!(_accountFormKey.currentState?.validate() ?? false)) return;
    final preview = widget.preview!;
    if (!preview.accountExists) {
      final evaluation = PasswordPolicy.evaluate(
        password: _password.text,
        confirmation: _passwordConfirmation.text,
        identity: PasswordIdentityInput(
          email: preview.email,
          firstName: preview.fullName.split(' ').first,
          lastName: preview.fullName.split(' ').skip(1).join(' '),
        ),
      );
      if (!evaluation.accepted) return;
    }
    setState(() => _step = 3);
  }

  Future<void> _acceptInvitation() async {
    final accountExists = widget.preview!.accountExists;
    if (!accountExists && !_personalDataConsentAccepted) {
      setState(() => _showAcceptanceErrors = true);
      return;
    }

    final success = await widget.onAccept(
      AcceptTeamInvitationInput(
        token: _token.text.trim(),
        password: _password.text,
        passwordConfirmation: _passwordConfirmation.text,
        personalDataConsentAccepted:
            !accountExists && _personalDataConsentAccepted,
        policyVersionIds: _acceptedPolicyIds,
      ),
    );
    if (success) {
      _token.clear();
      _password.clear();
      _passwordConfirmation.clear();
      await widget.onInvitationAccepted?.call();
    }
  }

  Future<void> _continueAfterAcceptance() async {
    final onInvitationAccepted = widget.onInvitationAccepted;
    if (onInvitationAccepted != null) {
      await onInvitationAccepted();
      return;
    }
    widget.onGoToLogin();
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.runes.length < PasswordPolicy.minimumLength) {
      return 'Use ao menos 12 caracteres.';
    }
    if (password.runes.length > PasswordPolicy.maximumLength) {
      return 'Use no máximo 128 caracteres.';
    }
    final preview = widget.preview;
    if (preview != null && !preview.accountExists) {
      final evaluation = PasswordPolicy.evaluate(
        password: password,
        confirmation: _passwordConfirmation.text,
        identity: PasswordIdentityInput(
          email: preview.email,
          firstName: preview.fullName.split(' ').first,
          lastName: preview.fullName.split(' ').skip(1).join(' '),
        ),
      );
      if (!evaluation.scoreAccepted ||
          !evaluation.identityAccepted ||
          !evaluation.commonPasswordAccepted) {
        return 'A senha ainda não atende a todos os requisitos.';
      }
    }
    return null;
  }

  void _handleBack() {
    if (widget.acceptance != null || _step == 0) {
      widget.onBack();
      return;
    }
    setState(() {
      _step -= 1;
      _showAcceptanceErrors = false;
    });
  }

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Convite', 'Políticas', 'Conta', 'Confirmação'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(labels.length, (index) {
            final active = index <= step;
            return Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(
                  right: index == labels.length - 1 ? 0 : 8,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF70F0A4)
                      : Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(48),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Etapa ${step + 1} de ${labels.length} • ${labels[step]}',
          style: const TextStyle(color: Color(0xFFC8D7FF)),
        ),
      ],
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: StudyAppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: StudyAppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: StudyAppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InvitationSummaryCard extends StatelessWidget {
  const _InvitationSummaryCard({required this.preview, this.expanded = false});

  final TeamInvitationPreview preview;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final expiry = preview.expiresAt;
    final rows = <(IconData, String)>[
      (Icons.business_outlined, preview.organizationName),
      (Icons.groups_outlined, preview.teamName),
      (Icons.badge_outlined, preview.teamRole),
      if (expanded)
        (Icons.admin_panel_settings_outlined, preview.profiles.join(', ')),
      if (expanded)
        (
          Icons.schedule_outlined,
          'Expira em ${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')} às ${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}',
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E0EF)),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(row.$1, size: 20, color: StudyAppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(row.$2)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudyAppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 20,
            color: StudyAppColors.accent,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: StudyAppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
