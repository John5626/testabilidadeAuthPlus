import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_theme.dart';
import '../../domain/studyapp_models.dart';
import '../widgets/studyapp_ui.dart';
import 'access_request_view.dart';
import 'approval_view.dart';
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

class _ResourceDetailViewState extends State<ResourceDetailView> {
  bool _revealed = false;
  int _seconds = 30;
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;
    return NavyPage(
      child: ContentWidth(
        maxWidth: 700,
        child: Column(
          children: [
            AppTopBar(onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: StudyAppColors.accent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            resource.iconLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resource.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'Detalhe do recurso protegido.',
                                style: TextStyle(color: Color(0xFFC8D7FF)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            const StatusPill(
                              label: 'Ativo',
                              color: Color(0xFF52DA97),
                            ),
                            const SizedBox(height: 5),
                            StatusPill(
                              label: resource.risk.label,
                              color: const Color(0xFFFF8C8C),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        children: [
                          _infoRow(
                            Icons.groups,
                            'Equipe / setor',
                            resource.team,
                            Icons.category_outlined,
                            'Categoria',
                            resource.category,
                          ),
                          const Divider(color: Color(0xFF1B4A97)),
                          _infoRow(
                            Icons.qr_code,
                            'Método',
                            resource.provisioning,
                            Icons.inventory_2_outlined,
                            'Provisionamento',
                            resource.vaultLabel,
                          ),
                          const Divider(color: Color(0xFF1B4A97)),
                          Row(
                            children: [
                              const Icon(Icons.tag, color: Color(0xFFC8D7FF)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ID do recurso\n${resource.id}',
                                  style: const TextStyle(
                                    color: Color(0xFFD9E5FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            color: Color(0xFFC8D7FF),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Descrição',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  resource.description,
                                  style: const TextStyle(
                                    color: Color(0xFFB8C7E8),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AccessRequestView(
                                viewModel: widget.viewModel,
                                resource: resource,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Solicitar acesso'),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ApprovalView(
                                viewModel: widget.viewModel,
                                request: widget.viewModel.data.pendingRequest,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Delegar'),
                        ),
                        OutlinedButton(
                          onPressed: () => showPrototypeMessage(
                            context,
                            'Auditoria filtrada para ${resource.name}.',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Ver auditoria'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lock, color: Color(0xFF60A5FA)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Acesso seguro',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              StatusPill(
                                label: 'Protegido e auditado',
                                color: Color(0xFF8FBEFF),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            child: _revealed
                                ? _secretContent()
                                : _hiddenContent(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'A visualização será registrada em auditoria e protegida pela política de acesso.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8FBEFF), fontSize: 12),
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

  Widget _hiddenContent() => Column(
    key: const ValueKey('hidden'),
    children: [
      const Text(
        'Confirme a ação para revelar temporariamente a credencial e o TOTP.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFB8C7E8)),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _reveal,
        icon: const Icon(Icons.visibility_outlined),
        label: const Text('Reautenticar e visualizar'),
      ),
    ],
  );

  Widget _secretContent() => Column(
    key: const ValueKey('revealed'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Senha de acesso',
        style: TextStyle(color: Color(0xFFC8D7FF), fontSize: 12),
      ),
      const SizedBox(height: 6),
      _secretLine('P@ss •••• 7K2', 'Senha copiada temporariamente.'),
      const SizedBox(height: 12),
      const Text(
        'Código TOTP atual',
        style: TextStyle(color: Color(0xFFC8D7FF), fontSize: 12),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(child: _secretLine('482 931', 'TOTP copiado.')),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF60A5FA),
            child: Text(
              '$_seconds',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'expira em\n${_seconds}s',
            style: const TextStyle(color: Color(0xFFD9E5FF), fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _hide,
        style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
        icon: const Icon(Icons.visibility_off_outlined),
        label: const Text('Ocultar agora'),
      ),
    ],
  );

  Widget _secretLine(String value, String message) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF11357E),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Copiar temporariamente',
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: value.replaceAll(' ', '')),
            );
            if (mounted) showPrototypeMessage(context, message);
          },
          icon: const Icon(Icons.copy, color: Color(0xFFD9E5FF)),
        ),
      ],
    ),
  );

  Widget _infoRow(
    IconData iconA,
    String labelA,
    String valueA,
    IconData iconB,
    String labelB,
    String valueB,
  ) => Row(
    children: [
      Expanded(child: _info(iconA, labelA, valueA)),
      Container(width: 1, height: 46, color: const Color(0xFF1B4A97)),
      const SizedBox(width: 12),
      Expanded(child: _info(iconB, labelB, valueB)),
    ],
  );
  Widget _info(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFFC8D7FF)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          '$label\n$value',
          style: const TextStyle(color: Color(0xFFD9E5FF), fontSize: 12),
        ),
      ),
    ],
  );

  void _reveal() {
    setState(() {
      _revealed = true;
      _seconds = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        _hide();
      } else {
        setState(() => _seconds -= 1);
      }
    });
  }

  void _hide() {
    _timer?.cancel();
    if (mounted) setState(() => _revealed = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
