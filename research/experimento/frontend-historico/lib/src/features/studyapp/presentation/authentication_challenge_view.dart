import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../domain/authentication.dart';
import 'widgets/studyapp_ui.dart';
import 'widgets/safe_policy_html.dart';

class PolicyOnboardingView extends StatefulWidget {
  const PolicyOnboardingView({
    required this.policies,
    required this.isBusy,
    required this.errorMessage,
    required this.onRetry,
    required this.onAccept,
    required this.onCancel,
    super.key,
  });

  final List<RequiredPolicy> policies;
  final bool isBusy;
  final String? errorMessage;
  final Future<bool> Function() onRetry;
  final Future<bool> Function() onAccept;
  final VoidCallback onCancel;

  @override
  State<PolicyOnboardingView> createState() => _PolicyOnboardingViewState();
}

class _PolicyOnboardingViewState extends State<PolicyOnboardingView> {
  int _currentIndex = 0;
  final Set<String> _acceptedPolicyIds = {};

  String get _policySet =>
      widget.policies.map((policy) => policy.policyVersionId).join('|');

  @override
  void didUpdateWidget(covariant PolicyOnboardingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPolicySet = oldWidget.policies
        .map((policy) => policy.policyVersionId)
        .join('|');
    if (oldPolicySet != _policySet) {
      _currentIndex = 0;
      _acceptedPolicyIds.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: ContentWidth(
        maxWidth: 720,
        child: Column(
          children: [
            AppTopBar(onBack: widget.isBusy ? null : widget.onCancel),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(21),
                child: GlassCard(
                  color: Colors.white,
                  padding: const EdgeInsets.all(21),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.policy_outlined,
                        size: 48,
                        color: StudyAppColors.accent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Políticas institucionais',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Leia e aceite cada documento vigente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: StudyAppColors.textSecondary),
                      ),
                      const SizedBox(height: 21),
                      if (widget.policies.isEmpty)
                        _PolicyLoadingState(
                          isBusy: widget.isBusy,
                          errorMessage: widget.errorMessage,
                          onRetry: widget.onRetry,
                        )
                      else ...[
                        _PolicyProgress(
                          current: _currentIndex + 1,
                          total: widget.policies.length,
                        ),
                        const SizedBox(height: 16),
                        _PolicyCard(policy: widget.policies[_currentIndex]),
                        Material(
                          color: Colors.transparent,
                          child: CheckboxListTile(
                            key: const Key('policy-explicit-acceptance'),
                            value: _acceptedPolicyIds.contains(
                              widget.policies[_currentIndex].policyVersionId,
                            ),
                            onChanged: widget.isBusy
                                ? null
                                : (value) => setState(() {
                                    final id = widget
                                        .policies[_currentIndex]
                                        .policyVersionId;
                                    if (value ?? false) {
                                      _acceptedPolicyIds.add(id);
                                    } else {
                                      _acceptedPolicyIds.remove(id);
                                    }
                                  }),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Li e aceito esta versão do documento.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text(
                              'Serão registrados a versão, data, hora e origem da confirmação.',
                            ),
                          ),
                        ),
                        if (widget.errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            widget.errorMessage!,
                            key: const Key('policy-error'),
                            style: const TextStyle(
                              color: StudyAppColors.danger,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (_currentIndex > 0) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: widget.isBusy
                                      ? null
                                      : () => setState(() => _currentIndex--),
                                  child: const Text('Anterior'),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: FilledButton(
                                key: const Key('policy-accept'),
                                onPressed:
                                    !_acceptedPolicyIds.contains(
                                          widget
                                              .policies[_currentIndex]
                                              .policyVersionId,
                                        ) ||
                                        widget.isBusy
                                    ? null
                                    : _advanceOrAccept,
                                child: widget.isBusy
                                    ? const _ButtonProgress()
                                    : Text(
                                        _currentIndex ==
                                                widget.policies.length - 1
                                            ? 'Aceitar e entrar'
                                            : 'Aceitar e avançar',
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      OutlinedButton(
                        key: const Key('challenge-cancel'),
                        onPressed: widget.isBusy ? null : widget.onCancel,
                        child: const Text('Cancelar e voltar ao login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _advanceOrAccept() async {
    if (_currentIndex < widget.policies.length - 1) {
      setState(() => _currentIndex++);
      return;
    }
    if (_acceptedPolicyIds.length == widget.policies.length) {
      await widget.onAccept();
    }
  }
}

class MfaChallengeView extends StatefulWidget {
  const MfaChallengeView({
    required this.isBusy,
    required this.errorMessage,
    required this.onVerify,
    required this.onCancel,
    super.key,
  });

  final bool isBusy;
  final String? errorMessage;
  final Future<bool> Function(String code) onVerify;
  final VoidCallback onCancel;

  @override
  State<MfaChallengeView> createState() => _MfaChallengeViewState();
}

class _MfaChallengeViewState extends State<MfaChallengeView> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: ContentWidth(
        maxWidth: 560,
        child: Column(
          children: [
            AppTopBar(onBack: widget.isBusy ? null : widget.onCancel),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(21),
                  child: GlassCard(
                    color: Colors.white,
                    padding: const EdgeInsets.all(21),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.phonelink_lock_outlined,
                            size: 48,
                            color: StudyAppColors.accent,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Verificação em duas etapas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Informe o código atual do seu aplicativo autenticador. '
                            'A sessão será criada somente após a validação.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: StudyAppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 21),
                          TextFormField(
                            key: const Key('mfa-code'),
                            controller: _code,
                            enabled: !widget.isBusy,
                            keyboardType: TextInputType.number,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(8),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Código de autenticação',
                              prefixIcon: Icon(Icons.password_outlined),
                              helperText: 'Digite o código de 6 ou 8 dígitos.',
                            ),
                            validator: (value) {
                              final length = value?.length ?? 0;
                              return length == 6 || length == 8
                                  ? null
                                  : 'Informe um código válido de 6 ou 8 dígitos.';
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          if (widget.errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              widget.errorMessage!,
                              key: const Key('mfa-error'),
                              style: const TextStyle(
                                color: StudyAppColors.danger,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const Key('mfa-submit'),
                            onPressed: widget.isBusy ? null : _submit,
                            child: widget.isBusy
                                ? const _ButtonProgress()
                                : const Text('Validar código'),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            key: const Key('challenge-cancel'),
                            onPressed: widget.isBusy ? null : widget.onCancel,
                            child: const Text('Cancelar e voltar ao login'),
                          ),
                        ],
                      ),
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
    if (widget.isBusy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.onVerify(_code.text);
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.policy});

  final RequiredPolicy policy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
    );
  }

  static String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _PolicyProgress extends StatelessWidget {
  const _PolicyProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Documento $current de $total',
          style: const TextStyle(
            color: StudyAppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(value: current / total, minHeight: 7),
      ],
    );
  }
}

class _PolicyLoadingState extends StatelessWidget {
  const _PolicyLoadingState({
    required this.isBusy,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool isBusy;
  final String? errorMessage;
  final Future<bool> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(21),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Column(
      children: [
        Text(
          errorMessage ?? 'Não foi possível carregar as políticas vigentes.',
          key: const Key('policy-error'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: StudyAppColors.danger),
        ),
        const SizedBox(height: 16),
        FilledButton.tonal(
          key: const Key('policy-retry'),
          onPressed: onRetry,
          child: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}

class _ButtonProgress extends StatelessWidget {
  const _ButtonProgress();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 22,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}
