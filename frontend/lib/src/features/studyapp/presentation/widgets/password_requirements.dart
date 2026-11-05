import 'package:flutter/material.dart';

import '../../domain/password_policy.dart';

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({required this.evaluation, super.key});

  final PasswordPolicyEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final items = [
      (evaluation.lengthAccepted, '12 a 128 caracteres'),
      (evaluation.scoreAccepted, 'Força mínima 3 de 4'),
      (
        evaluation.commonPasswordAccepted,
        'Não é uma senha comum ou comprometida',
      ),
      (evaluation.identityAccepted, 'Não contém nome ou e-mail'),
      (evaluation.confirmationAccepted, 'Confirmação exatamente igual'),
    ];
    return Semantics(
      label: evaluation.accepted
          ? 'A senha atende a todos os requisitos.'
          : 'A senha ainda não atende a todos os requisitos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos da senha',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    item.$1 ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: item.$1
                        ? const Color(0xFF2F8F5B)
                        : const Color(0xFF667085),
                  ),
                  const SizedBox(width: 7),
                  Expanded(child: Text(item.$2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PasswordRequirementsEditor extends StatefulWidget {
  const PasswordRequirementsEditor({
    required this.password,
    required this.confirmation,
    required this.identity,
    super.key,
  });

  final TextEditingController password;
  final TextEditingController confirmation;
  final PasswordIdentityInput identity;

  @override
  State<PasswordRequirementsEditor> createState() =>
      _PasswordRequirementsEditorState();
}

class _PasswordRequirementsEditorState
    extends State<PasswordRequirementsEditor> {
  @override
  void initState() {
    super.initState();
    widget.password.addListener(_refresh);
    widget.confirmation.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) => PasswordRequirements(
    evaluation: PasswordPolicy.evaluate(
      password: widget.password.text,
      confirmation: widget.confirmation.text,
      identity: widget.identity,
    ),
  );

  @override
  void dispose() {
    widget.password.removeListener(_refresh);
    widget.confirmation.removeListener(_refresh);
    super.dispose();
  }
}
