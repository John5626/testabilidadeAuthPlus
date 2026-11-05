import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../resource_revelation/presentation/revelation_view_model.dart';
import '../../domain/studyapp_models.dart';
import '../widgets/studyapp_ui.dart';
import 'workspace_view_model.dart';

class ResourceDetailView extends StatefulWidget {
  const ResourceDetailView({
    required this.viewModel,
    required this.resource,
    super.key,
  });
  final WorkspaceViewModel viewModel;
  final ProtectedResource resource;
  @override
  State<ResourceDetailView> createState() => _ResourceDetailViewState();
}

class _ResourceDetailViewState extends State<ResourceDetailView>
    with WidgetsBindingObserver {
  RevelationViewModel? _revelation;
  final _password = TextEditingController(), _code = TextEditingController();
  String? _request;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final repository = widget.viewModel.repository.revelation;
    final resource = widget.resource.revelationResource;
    if (repository != null && resource != null) {
      _revelation = RevelationViewModel(
        repository: repository,
        resource: resource,
        clipboard: _PlatformClipboard(),
        onSessionLost: widget.viewModel.onSessionInvalidated,
      );
      _request = resource.requests
          .where((r) => r.available(DateTime.now().toUtc()))
          .firstOrNull
          ?.id;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == false) _clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _clear();
    } else {
      _revelation?.checkDeadlines();
    }
  }

  void _clear() {
    _password.clear();
    _code.clear();
    unawaited(_revelation?.hide() ?? Future<void>.value());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _password.clear();
    _code.clear();
    _password.dispose();
    _code.dispose();
    _revelation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _revelation;
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _clear();
      },
      child: NavyPage(
        child: ContentWidth(
          maxWidth: 700,
          child: Column(
            children: [
              AppTopBar(
                onBack: () {
                  _clear();
                  Navigator.of(context).pop();
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionTitle(
                        widget.resource.name,
                        subtitle: 'Acesso protegido, temporário e auditado.',
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.resource.description,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${widget.resource.team} • ${widget.resource.category}',
                              style: const TextStyle(color: Color(0xFFC8D7FF)),
                            ),
                            const SizedBox(height: 10),
                            StatusPill(
                              label: widget.resource.criticalityLabel,
                              color: const Color(0xFF60A5FA),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (vm == null)
                        const GlassCard(
                          child: Text(
                            'A visualização deste recurso ainda não está disponível.',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      else
                        ListenableBuilder(
                          listenable: vm,
                          builder: (context, _) => _controls(vm),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls(RevelationViewModel vm) {
    final resource = vm.resource;
    final value = vm.value;
    final requests = resource.requests
        .where((r) => r.available(DateTime.now().toUtc()))
        .toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Visualização controlada',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (vm.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                vm.error!,
                style: const TextStyle(color: Color(0xFFFF8C8C)),
              ),
            ),
          if (!vm.hasSession) ...[
            if (requests.isEmpty) ...[
              const Text(
                'Não há autorização aprovada e vigente para este recurso. Solicite acesso e aguarde a decisão.',
                style: TextStyle(color: Color(0xFFD9E5FF)),
              ),
              const SizedBox(height: 10),
              for (final status
                  in resource.requests.map((r) => r.status).toSet())
                Text(
                  _requestStatus(status),
                  style: const TextStyle(color: Color(0xFFC8D7FF)),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _requestAccess(vm),
                icon: const Icon(Icons.lock_clock),
                label: const Text('Solicitar acesso'),
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                initialValue: requests.any((r) => r.id == _request)
                    ? _request
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Autorização aprovada',
                ),
                items: [
                  for (var i = 0; i < requests.length; i++)
                    DropdownMenuItem(
                      value: requests[i].id,
                      child: Text(
                        'Autorização ${i + 1}',
                        style: const TextStyle(color: Color(0xFF60A5FA)),
                      ),
                    ),
                ],
                onChanged: vm.busy || vm.requiresMfa
                    ? null
                    : (v) => setState(() => _request = v),
              ),
              const SizedBox(height: 16),
              if (vm.requiresMfa) ...[
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  autofillHints: const [],
                  autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Código do seu autenticador',
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: vm.busy || _request == null
                      ? null
                      : () {
                          final code = _code.text;
                          _code.clear();
                          unawaited(vm.verifyMfa(_request!, code));
                        },
                  child: const Text('Confirmar verificação'),
                ),
              ] else ...[
                TextField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [],
                  autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Confirme sua senha StudyApp',
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: vm.busy || _request == null
                      ? null
                      : () {
                          final password = _password.text;
                          _password.clear();
                          unawaited(vm.authenticate(_request!, password));
                        },
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Confirmar identidade'),
                ),
              ],
            ],
          ] else ...[
            Text(
              'Acesso encerra em ${vm.secondsLeft}s',
              style: const TextStyle(color: Color(0xFFC8D7FF)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (vm.canRevealCredential)
                  FilledButton(
                    onPressed: vm.busy ? null : () => vm.reveal('CREDENTIAL'),
                    child: const Text('Visualizar credenciais'),
                  ),
                if (vm.canRevealTotp)
                  FilledButton(
                    onPressed: vm.busy ? null : () => vm.reveal('TOTP'),
                    child: const Text('Visualizar código TOTP'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (value != null) ...[
              if (value.kind == 'CREDENTIAL') ...[
                if (value.login != null) _field('Login ou email', value.login!),
                if (value.password != null) _field('Senha', value.password!),
                for (final item in value.additionalFields.entries)
                  _field(item.key, item.value),
              ] else ...[
                _field('Código TOTP', value.code ?? ''),
                if (vm.canCopy)
                  OutlinedButton.icon(
                    onPressed: vm.busy
                        ? null
                        : () => vm.reveal('TOTP', copy: true),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar código TOTP'),
                  ),
              ],
            ] else
              const Text(
                'Escolha o conteúdo a visualizar. Códigos vencidos são ocultados automaticamente.',
                style: TextStyle(color: Color(0xFFD9E5FF)),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.visibility_off_outlined),
              label: const Text('Ocultar e encerrar'),
            ),
          ],
          if (vm.busy)
            const Padding(
              padding: EdgeInsets.all(10),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 16),
          const Text(
            'A autorização é conferida antes de cada operação. Sair da tela ou perder a sessão oculta os valores.',
            style: TextStyle(color: Color(0xFFC8D7FF), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFC8D7FF), fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
  String _requestStatus(String value) => switch (value) {
    'PENDENTE' => 'Solicitação pendente de aprovação.',
    'REJEITADA' => 'Solicitação rejeitada.',
    'EXPIRADA' => 'Autorização expirada.',
    'CANCELADA' => 'Autorização cancelada.',
    _ => 'Autorização indisponível.',
  };
  Future<void> _requestAccess(RevelationViewModel vm) async {
    final input = await showDialog<_AccessRequestInput>(
      context: context,
      builder: (_) =>
          _AccessRequestDialog(maxViewSeconds: vm.resource.maxViewSeconds),
    );
    if (input == null || !mounted) return;
    final reason = input.justification;
    final duration = int.tryParse(input.durationText);
    if (duration == null ||
        duration < 1 ||
        duration > vm.resource.maxViewSeconds) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um tempo dentro do limite da política.'),
        ),
      );
      return;
    }
    try {
      await vm.repository.requestAccess(vm.resource, reason, duration);
      await widget.viewModel.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solicitação enviada. Aguarde a aprovação antes de visualizar.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível enviar a solicitação.'),
          ),
        );
      }
    }
  }
}

class _AccessRequestInput {
  const _AccessRequestInput(this.justification, this.durationText);

  final String justification;
  final String durationText;

  @override
  String toString() => 'AccessRequestInput[REDACTED]';
}

class _AccessRequestDialog extends StatefulWidget {
  const _AccessRequestDialog({required this.maxViewSeconds});

  final int maxViewSeconds;

  @override
  State<_AccessRequestDialog> createState() => _AccessRequestDialogState();
}

class _AccessRequestDialogState extends State<_AccessRequestDialog> {
  final _justification = TextEditingController();
  late final TextEditingController _seconds;

  @override
  void initState() {
    super.initState();
    _seconds = TextEditingController(text: '${widget.maxViewSeconds}');
  }

  @override
  void dispose() {
    // O dialogo continua montado durante a animacao de saida da rota.
    _justification.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Solicitar acesso'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _justification,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Justificativa'),
        ),
        TextField(
          controller: _seconds,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Tempo em segundos (até ${widget.maxViewSeconds})',
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(
          context,
        ).pop(_AccessRequestInput(_justification.text, _seconds.text)),
        child: const Text('Enviar'),
      ),
    ],
  );
}

class _PlatformClipboard implements RevelationClipboard {
  @override
  Future<void> write(String value) =>
      Clipboard.setData(ClipboardData(text: value));
  @override
  Future<String?> read() async =>
      (await Clipboard.getData(Clipboard.kTextPlain))?.text;
  @override
  Future<void> clear() => Clipboard.setData(const ClipboardData(text: ''));
}
