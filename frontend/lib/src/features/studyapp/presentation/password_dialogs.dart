import 'package:flutter/material.dart';

import '../domain/password_policy.dart';
import 'studyapp_flow_controller.dart';
import 'widgets/password_requirements.dart';

Future<void> showPasswordRecoveryDialog(
  BuildContext context, {
  required StudyAppFlowController controller,
  required Future<bool> Function(String email) onRequestRecovery,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _PasswordRecoveryDialog(
      controller: controller,
      onRequestRecovery: onRequestRecovery,
    ),
  );
}

Future<bool?> showChangePasswordDialog(
  BuildContext context, {
  required PasswordIdentityInput identity,
  required Future<bool> Function(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  )
  onChangePassword,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _ChangePasswordDialog(
      identity: identity,
      onChangePassword: onChangePassword,
    ),
  );
}

class _PasswordRecoveryDialog extends StatefulWidget {
  const _PasswordRecoveryDialog({
    required this.controller,
    required this.onRequestRecovery,
  });

  final StudyAppFlowController controller;
  final Future<bool> Function(String email) onRequestRecovery;

  @override
  State<_PasswordRecoveryDialog> createState() =>
      _PasswordRecoveryDialogState();
}

class _PasswordRecoveryDialogState extends State<_PasswordRecoveryDialog> {
  final _email = TextEditingController();
  bool _requested = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_closeWhenRecoveryLinkOpens);
  }

  void _closeWhenRecoveryLinkOpens() {
    if (!mounted || widget.controller.stage != StudyAppStage.passwordReset) {
      return;
    }
    final route = ModalRoute.of(context);
    if (route != null && route.isActive) {
      Navigator.of(context).removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_requested ? 'Verifique seu e-mail' : 'Recuperar senha'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_requested) ...[
                const Text(
                  'Informe seu e-mail. Se houver uma conta, você receberá um link para redefinir a senha.',
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('recovery-email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
              ] else ...[
                const Text(
                  'Se houver uma conta para este e-mail, enviamos um link de recuperação. Abra o e-mail e toque no link para definir sua nova senha.',
                  key: Key('recovery-email-instructions'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (!_requested)
          FilledButton(
            key: const Key('recovery-submit'),
            onPressed: _busy ? null : _request,
            child: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar instruções'),
          ),
      ],
    );
  }

  Future<void> _request() async {
    if (!_email.text.contains('@')) {
      setState(() => _error = 'Informe um e-mail válido.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final success = await widget.onRequestRecovery(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _requested = success;
      _error = success
          ? null
          : 'Não foi possível enviar a solicitação. Tente novamente.';
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_closeWhenRecoveryLinkOpens);
    _email.dispose();
    super.dispose();
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({
    required this.identity,
    required this.onChangePassword,
  });

  final PasswordIdentityInput identity;

  final Future<bool> Function(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  )
  onChangePassword;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alterar senha'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('current-password'),
                controller: _current,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Senha atual'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('new-password'),
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  helperText: 'Use de 12 a 128 caracteres.',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
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
                key: const Key('confirm-new-password'),
                controller: _confirmation,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nova senha',
                ),
              ),
              const SizedBox(height: 12),
              PasswordRequirementsEditor(
                password: _password,
                confirmation: _confirmation,
                identity: widget.identity,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('change-password-submit'),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Alterar senha'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_current.text.isEmpty) {
      setState(() => _error = 'Informe sua senha atual.');
      return;
    }
    final evaluation = PasswordPolicy.evaluate(
      password: _password.text,
      confirmation: _confirmation.text,
      identity: widget.identity,
    );
    if (!evaluation.accepted) {
      setState(() => _error = 'A nova senha ainda não atende aos requisitos.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final success = await widget.onChangePassword(
      _current.text,
      _password.text,
      _confirmation.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _error = 'Não foi possível alterar a senha. Verifique os dados.';
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }
}
