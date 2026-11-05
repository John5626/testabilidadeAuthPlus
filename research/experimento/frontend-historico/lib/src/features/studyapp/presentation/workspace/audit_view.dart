import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/studyapp_models.dart';
import '../widgets/studyapp_ui.dart';
import 'workspace_view_model.dart';

class AuditView extends StatefulWidget {
  const AuditView({required this.viewModel, super.key});
  final WorkspaceViewModel viewModel;

  @override
  State<AuditView> createState() => _AuditViewState();
}

class _AuditViewState extends State<AuditView> {
  String _query = '';
  String _filter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final events = widget.viewModel.data.auditEvents.where((event) {
      final matchesQuery = '${event.title} ${event.subtitle}'
          .toLowerCase()
          .contains(_query.toLowerCase());
      final matchesFilter =
          _filter == 'Todos' ||
          (_filter == 'Alertas' && event.severity == AuditSeverity.alert) ||
          (_filter == 'Operações' && event.severity == AuditSeverity.operation);
      return matchesQuery && matchesFilter;
    }).toList();
    return ContentWidth(
      maxWidth: 780,
      child: CustomScrollView(
        key: const PageStorageKey('audit-scroll'),
        slivers: [
          const SliverToBoxAdapter(child: AppTopBar()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            sliver: SliverList.list(
              children: [
                const SectionTitle(
                  'Auditoria',
                  subtitle: 'Consulte eventos, alertas e registros de acesso.',
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar usuário, recurso ou evento',
                    hintStyle: const TextStyle(color: Color(0xFF9EB3E0)),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFC8D7FF),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0D2D6A),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF1B4A97)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...['Todos', 'Operações', 'Alertas'].map(
                      (value) => ChoiceChip(
                        label: Text(value),
                        selected: _filter == value,
                        onSelected: (_) => setState(() => _filter = value),
                        selectedColor: const Color(0xFF174A9B),
                        backgroundColor: const Color(0xFF0D2D6A),
                        side: const BorderSide(color: Color(0xFF1B4A97)),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ),
                    ActionChip(
                      label: const Text('Exportar'),
                      avatar: const Icon(
                        Icons.file_download_outlined,
                        size: 17,
                      ),
                      onPressed: widget.viewModel.data.profile.canAudit
                          ? _exportAudit
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _metrics(),
                const SizedBox(height: 14),
                ...events.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _eventCard(event),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metrics() {
    final events = widget.viewModel.data.auditEvents;
    final metrics = [
      (
        Icons.trending_up,
        '${events.length}',
        'Eventos carregados',
        const Color(0xFF7BC8FF),
      ),
      (
        Icons.check_circle_outline,
        '${events.where((event) => event.severity == AuditSeverity.operation).length}',
        'Operações',
        const Color(0xFF70F0A4),
      ),
      (
        Icons.shield_outlined,
        '${events.where((event) => event.severity == AuditSeverity.alert).length}',
        'Alertas',
        const Color(0xFFFF7C8B),
      ),
    ];
    return Row(
      children: metrics
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GlassCard(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Icon(item.$1, color: item.$4),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        item.$3,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFB8C7E8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _exportAudit() async {
    try {
      final csv = await widget.viewModel.exportAuditCsv();
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) {
        showPrototypeMessage(
          context,
          'Relatório CSV real copiado. Cole em um arquivo .csv para salvar.',
        );
      }
    } catch (error) {
      if (mounted) showPrototypeMessage(context, error.toString());
    }
  }

  Widget _eventCard(AuditEvent event) {
    final color = switch (event.severity) {
      AuditSeverity.info => const Color(0xFF7BC8FF),
      AuditSeverity.operation => const Color(0xFF70F0A4),
      AuditSeverity.alert => const Color(0xFFFF7C8B),
    };
    final icon = switch (event.severity) {
      AuditSeverity.info => Icons.visibility_outlined,
      AuditSeverity.operation => Icons.group_outlined,
      AuditSeverity.alert => Icons.gpp_bad_outlined,
    };
    final label = switch (event.severity) {
      AuditSeverity.info => 'Info',
      AuditSeverity.operation => 'Operação',
      AuditSeverity.alert => 'Alerta',
    };
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.18),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  event.subtitle,
                  style: const TextStyle(
                    color: Color(0xFFB8C7E8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                event.timeLabel,
                style: const TextStyle(color: Color(0xFFC8D7FF), fontSize: 11),
              ),
              const SizedBox(height: 6),
              StatusPill(label: label, color: color),
            ],
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }
}
