import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/authentication.dart';
import '../domain/studyapp_models.dart';
import '../domain/password_policy.dart';
import 'widgets/studyapp_ui.dart';
import 'widgets/password_requirements.dart';
import 'widgets/safe_policy_html.dart';

class RegistrationFlowView extends StatefulWidget {
  const RegistrationFlowView({
    required this.isBusy,
    required this.errorMessage,
    required this.onOpenPolicies,
    required this.onBack,
    required this.onSubmit,
    super.key,
  });

  final bool isBusy;
  final String? errorMessage;
  final Future<List<RequiredPolicy>> Function() onOpenPolicies;
  final VoidCallback onBack;
  final Future<bool> Function(RegistrationDraft draft) onSubmit;

  @override
  State<RegistrationFlowView> createState() => _RegistrationFlowViewState();
}

class _RegistrationFlowViewState extends State<RegistrationFlowView> {
  final _formKeys = List.generate(3, (_) => GlobalKey<FormState>());
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _organization = TextEditingController();
  final _domain = TextEditingController();
  final _team = TextEditingController(text: 'Equipe Principal');
  var _step = 0;
  var _termsAccepted = false;
  var _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: ContentWidth(
        maxWidth: 620,
        child: Column(
          children: [
            AppTopBar(onBack: _step == 0 ? widget.onBack : _previous),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Criar Conta Administrativa',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _stepSubtitle,
                      style: const TextStyle(
                        color: Color(0xFFC8D7FF),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _StepIndicator(currentStep: _step),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: GlassCard(
                        key: ValueKey(_step),
                        color: Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKeys[_step],
                          child: _stepContent(),
                        ),
                      ),
                    ),
                    if (widget.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.errorMessage!,
                        style: const TextStyle(color: Color(0xFFFFA7B1)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: Key('registration-next-$_step'),
                      onPressed: widget.isBusy ? null : _next,
                      child: widget.isBusy
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _step == 2 ? 'Criar organização' : 'Continuar',
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: widget.isBusy ? null : widget.onBack,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFC8D7FF),
                      ),
                      child: const Text('Já tenho uma conta'),
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

  String get _stepSubtitle => switch (_step) {
    0 =>
      'Comece pelos seus dados. Mostraremos apenas o necessário em cada etapa.',
    1 => 'Agora conte onde sua equipe vai usar o StudyApp.',
    _ => 'Revise os dados e confirme as condições de uso.',
  };

  Widget _stepContent() => switch (_step) {
    0 => _personalStep(),
    1 => _organizationStep(),
    _ => _reviewStep(),
  };

  Widget _personalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardTitle(Icons.person_outline, 'Seus dados'),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('registration-first-name'),
          controller: _firstName,
          decoration: const InputDecoration(
            labelText: 'Nome',
            prefixIcon: Icon(Icons.person_outline),
          ),
          textInputAction: TextInputAction.next,
          validator: _required,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('registration-last-name'),
          controller: _lastName,
          decoration: const InputDecoration(
            labelText: 'Sobrenome',
            prefixIcon: Icon(Icons.person_outline),
          ),
          textInputAction: TextInputAction.next,
          validator: _required,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('registration-email'),
          controller: _email,
          decoration: const InputDecoration(
            labelText: 'E-mail institucional',
            prefixIcon: Icon(Icons.mail_outline),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              (value ?? '').contains('@') ? null : 'Informe um e-mail válido.',
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('registration-password'),
          controller: _password,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Senha',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _showPassword ? 'Ocultar senha' : 'Mostrar senha',
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          validator: _validatePassword,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('registration-confirm-password'),
          controller: _confirmPassword,
          obscureText: !_showPassword,
          decoration: const InputDecoration(
            labelText: 'Confirmar senha',
            prefixIcon: Icon(Icons.lock_reset_outlined),
          ),
          validator: (value) =>
              value == _password.text ? null : 'As senhas não coincidem.',
        ),
        const SizedBox(height: 12),
        PasswordRequirementsEditor(
          password: _password,
          confirmation: _confirmPassword,
          identity: PasswordIdentityInput(
            email: _email.text,
            firstName: _firstName.text,
            lastName: _lastName.text,
          ),
        ),
      ],
    );
  }

  Widget _organizationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardTitle(Icons.business_outlined, 'Sua organização'),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('registration-organization'),
          controller: _organization,
          decoration: const InputDecoration(
            labelText: 'Empresa/Organização',
            prefixIcon: Icon(Icons.business_outlined),
          ),
          validator: _required,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _domain,
          decoration: const InputDecoration(
            labelText: 'Domínio',
            hintText: 'empresa.com.br',
            prefixIcon: Icon(Icons.language),
          ),
          validator: _required,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _team,
          decoration: const InputDecoration(
            labelText: 'Equipe inicial',
            prefixIcon: Icon(Icons.groups_2_outlined),
          ),
          validator: _required,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: StudyAppColors.accent,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Você será o primeiro administrador da organização e poderá convidar sua equipe depois.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardTitle(Icons.fact_check_outlined, 'Tudo certo?'),
        const SizedBox(height: 14),
        _reviewLine('Nome', _firstName.text),
        _reviewLine('Sobrenome', _lastName.text),
        _reviewLine('E-mail', _email.text),
        _reviewLine('Organização', _organization.text),
        _reviewLine('Equipe inicial', _team.text),
        const Divider(height: 28),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('registration-policy-link'),
            onPressed: _openPolicies,
            icon: const Icon(Icons.open_in_new_outlined),
            label: const Text(
              'Ler Política de Privacidade e Termos de Uso vigentes',
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _termsAccepted,
            onChanged: (value) =>
                setState(() => _termsAccepted = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Autorizo o tratamento dos meus dados pessoais.'),
            subtitle: const Text(
              'Seu consentimento será registrado. As versões vigentes dos termos e políticas deverão ser aceitas no primeiro acesso.',
            ),
          ),
        ),
        if (!_termsAccepted)
          const Text(
            'O aceite é necessário para continuar.',
            style: TextStyle(color: StudyAppColors.danger, fontSize: 12),
          ),
      ],
    );
  }

  Widget _cardTitle(IconData icon, String label) => Row(
    children: [
      Icon(icon, color: StudyAppColors.accent),
      const SizedBox(width: 10),
      Text(
        label,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
    ],
  );

  Widget _reviewLine(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: StudyAppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Campo obrigatório.' : null;

  String? _validatePassword(String? value) {
    final evaluation = PasswordPolicy.evaluate(
      password: value ?? '',
      confirmation: _confirmPassword.text,
      identity: PasswordIdentityInput(
        email: _email.text,
        firstName: _firstName.text,
        lastName: _lastName.text,
      ),
    );
    return evaluation.lengthAccepted &&
            evaluation.scoreAccepted &&
            evaluation.commonPasswordAccepted &&
            evaluation.identityAccepted
        ? null
        : 'A senha ainda não atende a todos os requisitos.';
  }

  Future<void> _next() async {
    if (!(_formKeys[_step].currentState?.validate() ?? false)) return;
    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }
    if (!_termsAccepted) {
      setState(() {});
      return;
    }
    await widget.onSubmit(
      RegistrationDraft(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirmPassword.text,
        organizationName: _organization.text.trim(),
        organizationDomain: _domain.text.trim(),
        teamName: _team.text.trim(),
        personalDataConsentAccepted: _termsAccepted,
      ),
    );
  }

  void _previous() => setState(() => _step -= 1);

  Future<void> _openPolicies() {
    return showDialog<void>(
      context: context,
      builder: (context) =>
          _CurrentPoliciesDialog(loadPolicies: widget.onOpenPolicies),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _email,
      _password,
      _confirmPassword,
      _organization,
      _domain,
      _team,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}

class _CurrentPoliciesDialog extends StatefulWidget {
  const _CurrentPoliciesDialog({required this.loadPolicies});

  final Future<List<RequiredPolicy>> Function() loadPolicies;

  @override
  State<_CurrentPoliciesDialog> createState() => _CurrentPoliciesDialogState();
}

class _CurrentPoliciesDialogState extends State<_CurrentPoliciesDialog> {
  late Future<List<RequiredPolicy>> _policies;

  @override
  void initState() {
    super.initState();
    _policies = widget.loadPolicies();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Dialog(
      key: const Key('current-policies-dialog'),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: screen.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Política de Privacidade e Termos de Uso',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Estas são as versões publicadas e vigentes no momento.',
                style: TextStyle(color: StudyAppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<RequiredPolicy>>(
                  future: _policies,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _PolicyLoadError(onRetry: _retry);
                    }
                    final policies = snapshot.data ?? const [];
                    return ListView.separated(
                      itemCount: policies.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) =>
                          _CurrentPolicyCard(policy: policies[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _retry() {
    setState(() {
      _policies = widget.loadPolicies();
    });
  }
}

class _CurrentPolicyCard extends StatelessWidget {
  const _CurrentPolicyCard({required this.policy});

  final RequiredPolicy policy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${policy.title}, versão ${policy.version}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFD8E0EF)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              policy.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '${policy.type} • versão ${policy.version} • vigente desde ${_date(policy.effectiveAt)}',
              style: const TextStyle(
                color: StudyAppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            SafePolicyHtml(html: policy.content),
            const SizedBox(height: 16),
            Text(
              'Integridade: ${policy.contentHash}',
              style: const TextStyle(
                color: StudyAppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _PolicyLoadError extends StatelessWidget {
  const _PolicyLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Não foi possível carregar as políticas vigentes.',
            key: Key('current-policies-error'),
            textAlign: TextAlign.center,
            style: TextStyle(color: StudyAppColors.danger),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Você', 'Organização', 'Confirmar'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? StudyAppColors.accentSoft : Colors.white24,
                  borderRadius: BorderRadius.circular(500),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[index],
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
