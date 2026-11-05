import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/studyapp_models.dart';
import '../widgets/studyapp_ui.dart';
import 'workspace_view_model.dart';

class ResourceFormView extends StatefulWidget {
  const ResourceFormView({required this.viewModel, super.key});
  final WorkspaceViewModel viewModel;

  @override
  State<ResourceFormView> createState() => _ResourceFormViewState();
}

class _ResourceFormViewState extends State<ResourceFormView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _category = 'Infraestrutura';
  ResourceRisk _risk = ResourceRisk.critical;
  String _provisioning = 'QR Code';

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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(
                        'Cadastro de recurso',
                        subtitle:
                            'Cadastre um novo recurso protegido por TOTP.',
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label('Nome do recurso'),
                            TextFormField(
                              controller: _name,
                              style: const TextStyle(color: Colors.white),
                              decoration: _darkInput('Ex.: AWS Produção'),
                              validator: _required,
                            ),
                            const SizedBox(height: 14),
                            _label('Descrição'),
                            TextFormField(
                              controller: _description,
                              style: const TextStyle(color: Colors.white),
                              minLines: 2,
                              maxLines: 4,
                              decoration: _darkInput(
                                'Como esse recurso será utilizado?',
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 14),
                            _label('Categoria'),
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              dropdownColor: const Color(0xFF0D2D6A),
                              style: const TextStyle(color: Colors.white),
                              decoration: _darkInput(null),
                              items:
                                  [
                                        'Infraestrutura',
                                        'Financeiro',
                                        'Operação',
                                        'Produtividade',
                                      ]
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) =>
                                  setState(() => _category = value!),
                            ),
                            const SizedBox(height: 14),
                            _label('Nível de acesso'),
                            SegmentedButton<ResourceRisk>(
                              segments: ResourceRisk.values
                                  .map(
                                    (risk) => ButtonSegment(
                                      value: risk,
                                      label: Text(risk.label),
                                    ),
                                  )
                                  .toList(),
                              selected: {_risk},
                              onSelectionChanged: (value) =>
                                  setState(() => _risk = value.first),
                              showSelectedIcon: false,
                              style: ButtonStyle(
                                foregroundColor: const WidgetStatePropertyAll(
                                  Colors.white,
                                ),
                                backgroundColor:
                                    WidgetStateProperty.resolveWith(
                                      (states) =>
                                          states.contains(WidgetState.selected)
                                          ? (_risk == ResourceRisk.critical
                                                ? const Color(0xFFFF3B3B)
                                                : StudyAppColors.accent)
                                          : const Color(0xFF0D2D6A),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _label('Método de provisionamento'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  ['QR Code', 'Chave manual', 'Importação']
                                      .map(
                                        (value) => ChoiceChip(
                                          label: Text(value),
                                          selected: _provisioning == value,
                                          onSelected: (_) => setState(
                                            () => _provisioning = value,
                                          ),
                                          selectedColor: StudyAppColors.accent,
                                          backgroundColor: const Color(
                                            0xFF0D2D6A,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF1B4A97),
                                          ),
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: widget.viewModel.isBusy ? null : _save,
                        icon: const Icon(Icons.lock),
                        label: const Text('Salvar recurso'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(height: 14),
                      const GlassCard(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFF70F0A4),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'O segredo será referenciado no cofre escolhido no primeiro acesso.',
                                style: TextStyle(color: Color(0xFFD9E5FF)),
                              ),
                            ),
                          ],
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

  InputDecoration _darkInput(String? hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9EB3E0)),
    filled: true,
    fillColor: const Color(0xFF0A2860),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF1B4A97)),
      borderRadius: BorderRadius.circular(10),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF60A5FA)),
      borderRadius: BorderRadius.circular(10),
    ),
  );
  Widget _label(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      value,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    ),
  );
  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Campo obrigatório.' : null;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.viewModel.createResource(
      name: _name.text.trim(),
      description: _description.text.trim(),
      category: _category,
      risk: _risk,
      provisioning: _provisioning,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }
}
