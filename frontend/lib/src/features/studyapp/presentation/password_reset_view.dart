import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/password_policy.dart';
import 'widgets/studyapp_ui.dart';
import 'widgets/password_requirements.dart';

class PasswordResetView extends StatefulWidget {
  const PasswordResetView({
    required this.isBusy,
    required this.linkVerified,
    required this.linkInvalid,
    required this.completed,
    required this.errorMessage,
    required this.onRetryPreview,
    required this.onReset,
    required this.onLogin,
    super.key,
  });

  final bool isBusy;
  final bool linkVerified;
  final bool linkInvalid;
  final bool completed;
  final String? errorMessage;
  final Future<void> Function() onRetryPreview;
  final Future<bool> Function(String password, String confirmation) onReset;
  final VoidCallback onLogin;

  @override
  State<PasswordResetView> createState() => _PasswordResetViewState();
}

class _PasswordResetViewState extends State<PasswordResetView> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscure = true;
  String? _validationError;

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: ContentWidth(
        maxWidth: 560,
        child: Column(
          children: [
            AppTopBar(onBack: widget.isBusy ? null : widget.onLogin),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(21),
                  child: GlassCard(
                    color: Colors.white,
                    padding: const EdgeInsets.all(21),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.lock_reset_outlined,
                          size: 48,
                          color: StudyAppColors.accent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.completed
                              ? 'Senha redefinida'
                              : 'Redefinir senha',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (widget.completed) ...[
                          const Text(
                            'Entre com a nova senha. As sessões anteriores foram encerradas.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            key: const Key('password-reset-login'),
                            onPressed: widget.onLogin,
                            child: const Text('Ir para login'),
                          ),
                        ] else if (widget.linkInvalid) ...[
                          const Text(
                            'Este link não está disponível. Solicite um novo e-mail de recuperação.',
                            key: Key('password-reset-invalid-link'),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: widget.onLogin,
                            child: const Text('Voltar ao login'),
                          ),
                        ] else if (!widget.linkVerified) ...[
                          if (widget.isBusy)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            Text(
                              widget.errorMessage ??
                                  'Não foi possível verificar o link.',
                              key: const Key('password-reset-preview-error'),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: widget.onRetryPreview,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ] else ...[
                          const Text(
                            'Defina uma nova senha para sua conta. O link será usado uma única vez.',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            key: const Key('password-reset-new-password'),
                            controller: _password,
                            obscureText: _obscure,
                            enableSuggestions: false,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Nova senha',
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
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('password-reset-confirmation'),
                            controller: _confirmation,
                            obscureText: _obscure,
                            enableSuggestions: false,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: const InputDecoration(
                              labelText: 'Confirmar nova senha',
                            ),
                          ),
                          const SizedBox(height: 12),
                          PasswordRequirementsEditor(
                            password: _password,
                            confirmation: _confirmation,
                            identity: const PasswordIdentityInput(
                              email: '',
                              firstName: '',
                            ),
                          ),
                          if (_validationError != null ||
                              widget.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _validationError ?? widget.errorMessage!,
                              key: const Key('password-reset-error'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            key: const Key('password-reset-submit'),
                            onPressed: widget.isBusy ? null : _submit,
                            child: widget.isBusy
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Redefinir senha'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final evaluation = PasswordPolicy.evaluate(
      password: _password.text,
      confirmation: _confirmation.text,
      identity: const PasswordIdentityInput(email: '', firstName: ''),
    );
    if (!evaluation.accepted) {
      setState(
        () =>
            _validationError = 'A nova senha ainda não atende aos requisitos.',
      );
      return;
    }
    setState(() => _validationError = null);
    final success = await widget.onReset(_password.text, _confirmation.text);
    if (success) {
      _password.clear();
      _confirmation.clear();
    }
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }
}
