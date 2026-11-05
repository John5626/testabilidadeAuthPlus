import 'package:flutter/material.dart';

import '../../domain/studyapp_models.dart';
import '../widgets/studyapp_ui.dart';
import 'workspace_view_model.dart';

class InstitutionalPoliciesView extends StatefulWidget {
  const InstitutionalPoliciesView({required this.viewModel, super.key});

  final WorkspaceViewModel viewModel;

  @override
  State<InstitutionalPoliciesView> createState() =>
      _InstitutionalPoliciesViewState();
}

class _InstitutionalPoliciesViewState extends State<InstitutionalPoliciesView> {
  List<InstitutionalPolicy> _policies = const [];
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: ContentWidth(
        maxWidth: 800,
        child: Column(
          children: [
            AppTopBar(onBack: () => Navigator.pop(context)),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: SectionTitle(
                            'Políticas institucionais',
                            subtitle:
                                'Gerencie versões, vigência e publicação.',
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _busy ? null : _createPolicy,
                          icon: const Icon(Icons.add),
                          label: const Text('Nova'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_busy)
                      const Center(child: CircularProgressIndicator())
                    else if (_error != null)
                      GlassCard(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFFFA7B1)),
                        ),
                      )
                    else if (_policies.isEmpty)
                      const GlassCard(
                        child: Text(
                          'Nenhuma política cadastrada.',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    else
                      ..._policies.map(_policyCard),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _policyCard(InstitutionalPolicy policy) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.policy_outlined, color: Color(0xFF60A5FA)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policy.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${policy.code} • ${policy.type}',
                        style: const TextStyle(color: Color(0xFFB8C7E8)),
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  label: policy.status,
                  color: policy.status == 'ACTIVE'
                      ? const Color(0xFF70F0A4)
                      : const Color(0xFFFF7C8B),
                ),
              ],
            ),
            const Divider(height: 22, color: Color(0xFF1B4A97)),
            ...policy.versions.map(
              (version) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Versão ${version.version}',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${version.status} • ${version.required ? 'obrigatória' : 'opcional'} • vigência ${_date(version.effectiveAt)}',
                  style: const TextStyle(color: Color(0xFFB8C7E8)),
                ),
                trailing: version.status == 'DRAFT'
                    ? TextButton(
                        onPressed: _busy
                            ? null
                            : () => _publish(policy.id, version.id),
                        child: const Text('Publicar'),
                      )
                    : const Icon(Icons.check_circle, color: Color(0xFF70F0A4)),
              ),
            ),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _createVersion(policy),
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Nova versão'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _editMetadata(policy),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                if (policy.status == 'ACTIVE')
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _deactivate(policy),
                    icon: const Icon(Icons.block_outlined),
                    label: const Text('Inativar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final policies = await widget.viewModel.guardSession(
        widget.viewModel.repository.listInstitutionalPolicies,
      );
      if (mounted) setState(() => _policies = policies);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createPolicy() async {
    final draft = await _policyDialog();
    if (draft == null) return;
    await _mutate(
      () => widget.viewModel.guardSession(
        () => widget.viewModel.repository.createInstitutionalPolicy(draft),
      ),
    );
  }

  Future<void> _createVersion(InstitutionalPolicy policy) async {
    final draft = await _versionDialog();
    if (draft == null) return;
    await _mutate(
      () => widget.viewModel.guardSession(
        () => widget.viewModel.repository.createInstitutionalPolicyVersion(
          policyId: policy.id,
          version: draft.$1,
          content: draft.$2,
          required: draft.$3,
          effectiveAt: draft.$4,
        ),
      ),
    );
  }

  Future<void> _editMetadata(InstitutionalPolicy policy) async {
    final title = TextEditingController(text: policy.title);
    final type = TextEditingController(text: policy.type);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar política'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: type,
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (save == true && title.text.trim().isNotEmpty) {
      await _mutate(
        () => widget.viewModel.guardSession(
          () => widget.viewModel.repository.updateInstitutionalPolicy(
            policyId: policy.id,
            title: title.text,
            type: type.text,
          ),
        ),
      );
    }
    title.dispose();
    type.dispose();
  }

  Future<void> _publish(String policyId, String versionId) => _mutate(
    () => widget.viewModel.guardSession(
      () => widget.viewModel.repository.publishInstitutionalPolicyVersion(
        policyId: policyId,
        versionId: versionId,
      ),
    ),
  );

  Future<void> _deactivate(InstitutionalPolicy policy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inativar política'),
        content: Text('Inativar ${policy.title} sem apagar o histórico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Inativar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _mutate(
        () => widget.viewModel.guardSession(
          () => widget.viewModel.repository.deactivateInstitutionalPolicy(
            policy.id,
          ),
        ),
      );
    }
  }

  Future<void> _mutate(Future<Object?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _load();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<SaveInstitutionalPolicyInput?> _policyDialog() async {
    final code = TextEditingController();
    final title = TextEditingController();
    final type = TextEditingController(text: 'PRIVACY');
    final version = TextEditingController(text: '1.0');
    final content = TextEditingController();
    var required = true;
    final result = await showDialog<SaveInstitutionalPolicyInput>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova política'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: code,
                    decoration: const InputDecoration(labelText: 'Código'),
                  ),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  TextField(
                    controller: type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                  ),
                  TextField(
                    controller: version,
                    decoration: const InputDecoration(labelText: 'Versão'),
                  ),
                  TextField(
                    controller: content,
                    minLines: 5,
                    maxLines: 10,
                    decoration: const InputDecoration(labelText: 'Conteúdo'),
                  ),
                  SwitchListTile(
                    value: required,
                    title: const Text('Aceite obrigatório'),
                    onChanged: (value) =>
                        setDialogState(() => required = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if ([
                  code,
                  title,
                  type,
                  version,
                  content,
                ].any((controller) => controller.text.trim().isEmpty)) {
                  return;
                }
                Navigator.pop(
                  context,
                  SaveInstitutionalPolicyInput(
                    code: code.text,
                    title: title.text,
                    type: type.text,
                    version: version.text,
                    content: content.text,
                    required: required,
                    effectiveAt: DateTime.now().toUtc(),
                  ),
                );
              },
              child: const Text('Criar rascunho'),
            ),
          ],
        ),
      ),
    );
    code.dispose();
    title.dispose();
    type.dispose();
    version.dispose();
    content.dispose();
    return result;
  }

  Future<(String, String, bool, DateTime)?> _versionDialog() async {
    final version = TextEditingController();
    final content = TextEditingController();
    var required = true;
    final result = await showDialog<(String, String, bool, DateTime)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova versão'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: version,
                  decoration: const InputDecoration(labelText: 'Versão'),
                ),
                TextField(
                  controller: content,
                  minLines: 5,
                  maxLines: 10,
                  decoration: const InputDecoration(labelText: 'Conteúdo'),
                ),
                SwitchListTile(
                  value: required,
                  title: const Text('Aceite obrigatório'),
                  onChanged: (value) => setDialogState(() => required = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (version.text.trim().isEmpty ||
                    content.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, (
                  version.text,
                  content.text,
                  required,
                  DateTime.now().toUtc(),
                ));
              },
              child: const Text('Criar rascunho'),
            ),
          ],
        ),
      ),
    );
    version.dispose();
    content.dispose();
    return result;
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
