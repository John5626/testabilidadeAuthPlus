import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import 'studyapp_flow_controller.dart';
import 'password_dialogs.dart';
import 'widgets/studyapp_ui.dart';

class LoginView extends StatefulWidget {
  const LoginView({
    required this.controller,
    required this.isBusy,
    required this.errorMessage,
    required this.noticeMessage,
    required this.onBack,
    required this.onCreateAccount,
    required this.onAcceptInvitation,
    required this.onLogin,
    required this.onRequestPasswordRecovery,
    super.key,
  });

  final StudyAppFlowController controller;
  final bool isBusy;
  final String? errorMessage;
  final String? noticeMessage;
  final VoidCallback onBack;
  final VoidCallback onCreateAccount;
  final VoidCallback onAcceptInvitation;
  final Future<bool> Function(String email, String password) onLogin;
  final Future<bool> Function(String email) onRequestPasswordRecovery;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: ContentWidth(
        maxWidth: 520,
        child: Column(
          children: [
            AppTopBar(onBack: widget.onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Gestão segura para suas senhas e códigos TOTP',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      color: Colors.white,
                      padding: const EdgeInsets.all(22),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Bem-vindo!',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Faça login para acessar sua conta',
                                style: TextStyle(
                                  color: StudyAppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _email,
                                autofillHints: const [
                                  AutofillHints.username,
                                  AutofillHints.email,
                                ],
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: (value) =>
                                    (value ?? '').contains('@')
                                    ? null
                                    : 'Informe um e-mail válido.',
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscure
                                        ? 'Mostrar senha'
                                        : 'Ocultar senha',
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) => (value ?? '').isNotEmpty
                                    ? null
                                    : 'Informe sua senha.',
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: widget.isBusy
                                      ? null
                                      : () => showPasswordRecoveryDialog(
                                          context,
                                          controller: widget.controller,
                                          onRequestRecovery:
                                              widget.onRequestPasswordRecovery,
                                        ),
                                  child: const Text('Esqueci minha senha'),
                                ),
                              ),
                              if (widget.errorMessage != null)
                                Text(
                                  widget.errorMessage!,
                                  style: const TextStyle(
                                    color: StudyAppColors.danger,
                                  ),
                                ),
                              if (widget.noticeMessage != null)
                                Text(
                                  widget.noticeMessage!,
                                  key: const Key('login-notice'),
                                  style: const TextStyle(
                                    color: StudyAppColors.success,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              FilledButton(
                                key: const Key('login-submit'),
                                onPressed: widget.isBusy ? null : _submit,
                                child: widget.isBusy
                                    ? const SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Entrar'),
                              ),
                              const SizedBox(height: 14),
                              const Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      'ou continue com',
                                      style: TextStyle(
                                        color: StudyAppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: () => showPrototypeMessage(
                                  context,
                                  'SSO institucional será conectado ao provedor da organização.',
                                ),
                                icon: const Icon(Icons.business),
                                label: const Text('Conta Institucional (SSO)'),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('Não tem uma conta?'),
                                  TextButton(
                                    onPressed: widget.onCreateAccount,
                                    child: const Text('Faça seu cadastro!'),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                key: const Key('login-accept-invitation'),
                                onPressed: widget.onAcceptInvitation,
                                icon: const Icon(
                                  Icons.mark_email_read_outlined,
                                ),
                                label: const Text(
                                  'Recebi um convite para equipe',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Future<void> _submit() async {
    if (widget.isBusy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await widget.onLogin(_email.text.trim(), _password.text);
    if (success) {
      TextInput.finishAutofillContext();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
