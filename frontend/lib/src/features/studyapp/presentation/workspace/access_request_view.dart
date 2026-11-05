import 'package:flutter/material.dart';

import '../../domain/studyapp_models.dart';
import '../widgets/studyapp_ui.dart';
import 'workspace_view_model.dart';

class AccessRequestView extends StatefulWidget {
  const AccessRequestView({
    required this.viewModel,
    required this.resource,
    super.key,
  });
  final WorkspaceViewModel viewModel;
  final ProtectedResource resource;

  @override
  State<AccessRequestView> createState() => _AccessRequestViewState();
}

class _AccessRequestViewState extends State<AccessRequestView> {
  final _formKey = GlobalKey<FormState>();
  final _justification = TextEditingController(
    text:
        'Necessário para manutenção do ambiente de produção e validação de credenciais.',
  );
  String _accessType = 'Visualização controlada do acesso';
  int _duration = 15;
  String _priority = 'Alta';

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: ContentWidth(
        maxWidth: 680,
        child: Column(
          children: [
            AppTopBar(onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(
                        'Solicitação de acesso',
                        subtitle:
                            'Solicite acesso temporário a um recurso protegido.',
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label('Recurso'),
                            _readonly(
                              widget.resource.name,
                              Icons.layers_outlined,
                            ),
                            const SizedBox(height: 12),
                            _label('Solicitante'),
                            _readonly(
                              widget.viewModel.data.profile.fullName,
                              Icons.person_outline,
                            ),
                            const SizedBox(height: 12),
                            _label('Justificativa'),
                            TextFormField(
                              controller: _justification,
                              style: const TextStyle(color: Colors.white),
                              minLines: 3,
                              maxLines: 5,
                              decoration: _decoration(),
                              validator: (value) =>
                                  (value ?? '').trim().length >= 15
                                  ? null
                                  : 'Detalhe a necessidade do acesso.',
                            ),
                            const SizedBox(height: 12),
                            _label('Tipo de acesso'),
                            ...[
                              'Visualização controlada do acesso',
                              'Delegação temporária',
                            ].map(_accessOption),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    initialValue: _duration,
                                    dropdownColor: const Color(0xFF0D2D6A),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _decoration(
                                      label: 'Duração desejada',
                                    ),
                                    items: [15, 30, 60]
                                        .map(
                                          (value) => DropdownMenuItem(
                                            value: value,
                                            child: Text('$value minutos'),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _duration = value!),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _priority,
                                    dropdownColor: const Color(0xFF0D2D6A),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _decoration(
                                      label: 'Prioridade',
                                    ),
                                    items: ['Baixa', 'Média', 'Alta']
                                        .map(
                                          (value) => DropdownMenuItem(
                                            value: value,
                                            child: Text(value),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _priority = value!),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: widget.viewModel.isBusy
                                  ? null
                                  : _submit,
                              child: const Text('Enviar'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'A solicitação será auditada e enviada para aprovação.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8FBEFF),
                          fontSize: 12,
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
    );
  }

  Widget _label(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      value,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    ),
  );
  Widget _readonly(String value, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF0A2860),
      border: Border.all(color: const Color(0xFF1B4A97)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFFC8D7FF)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  Widget _accessOption(String value) {
    final selected = _accessType == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _accessType = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF174A9B) : const Color(0xFF0A2860),
            border: Border.all(color: const Color(0xFF1B4A97)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: const Color(0xFF60A5FA),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(value, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({String? label}) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFFC8D7FF)),
    filled: true,
    fillColor: const Color(0xFF0A2860),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF1B4A97)),
      borderRadius: BorderRadius.circular(9),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF60A5FA)),
      borderRadius: BorderRadius.circular(9),
    ),
  );

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.viewModel.requestAccess(
      resource: widget.resource,
      justification: _justification.text.trim(),
      accessType: _accessType,
      durationMinutes: _duration,
      priority: _priority,
    );
    if (mounted) {
      showPrototypeMessage(context, 'Solicitação enviada com status pendente.');
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _justification.dispose();
    super.dispose();
  }
}
