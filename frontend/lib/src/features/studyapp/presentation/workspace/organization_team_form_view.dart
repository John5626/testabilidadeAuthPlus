import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/studyapp_models.dart';
import '../widgets/studyapp_ui.dart';
import 'workspace_view_model.dart';

class OrganizationTeamFormView extends StatefulWidget {
  const OrganizationTeamFormView({
    required this.viewModel,
    this.team,
    super.key,
  });

  final WorkspaceViewModel viewModel;
  final OrganizationTeam? team;

  @override
  State<OrganizationTeamFormView> createState() =>
      _OrganizationTeamFormViewState();
}

class _OrganizationTeamFormViewState extends State<OrganizationTeamFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _acronym;
  late final TextEditingController _description;
  String? _responsibleUserId;
  String? _errorMessage;

  bool get _editing => widget.team != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.team?.name ?? '');
    _acronym = TextEditingController(text: widget.team?.acronym ?? '');
    _description = TextEditingController(text: widget.team?.description ?? '');
    final members = widget.viewModel.data.members;
    _responsibleUserId =
        widget.team?.responsibleUserId ??
        (members.isEmpty ? null : members.first.id);
  }

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: ContentWidth(
        maxWidth: 620,
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
                      SectionTitle(
                        _editing ? 'Editar equipe' : 'Nova equipe',
                        subtitle: _editing
                            ? 'Atualize os dados e o responsável pela equipe.'
                            : 'Crie um novo escopo de usuários e recursos.',
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        color: Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              key: const Key('team-name'),
                              controller: _name,
                              decoration: const InputDecoration(
                                labelText: 'Nome da equipe',
                                prefixIcon: Icon(Icons.groups_outlined),
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('team-acronym'),
                              controller: _acronym,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Sigla (opcional)',
                                prefixIcon: Icon(Icons.short_text),
                              ),
                              validator: (value) => (value ?? '').length <= 10
                                  ? null
                                  : 'Use no máximo 10 caracteres.',
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _description,
                              minLines: 3,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Descrição e finalidade',
                                prefixIcon: Icon(Icons.description_outlined),
                                alignLabelWithHint: true,
                              ),
                              validator: (value) =>
                                  (value ?? '').trim().length >= 10
                                  ? null
                                  : 'Descreva a finalidade da equipe.',
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              key: const Key('team-admin-name'),
                              initialValue: _responsibleUserId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Administrador responsável',
                                prefixIcon: Icon(
                                  Icons.admin_panel_settings_outlined,
                                ),
                              ),
                              items: widget.viewModel.data.members
                                  .where(
                                    (member) =>
                                        member.status ==
                                        TeamMemberStatus.active,
                                  )
                                  .map(
                                    (member) => DropdownMenuItem(
                                      value: member.id,
                                      child: Text(member.fullName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _responsibleUserId = value),
                              validator: (value) => value == null
                                  ? 'Selecione o responsável.'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F0FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: StudyAppColors.accent,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'A equipe será criada ativa. Usuários e recursos deverão ser vinculados explicitamente depois.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFFA7B1)),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        key: const Key('save-team'),
                        onPressed: widget.viewModel.isBusy ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          _editing ? 'Salvar alterações' : 'Criar equipe',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cancelar'),
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

  String? _required(String? value) {
    return (value ?? '').trim().isEmpty ? 'Campo obrigatório.' : null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final responsibleUserId = _responsibleUserId;
    if (responsibleUserId == null) return;
    try {
      await widget.viewModel.saveTeam(
        SaveOrganizationTeamInput(
          teamId: widget.team?.id,
          name: _name.text.trim(),
          acronym: _acronym.text.trim().isEmpty
              ? null
              : _acronym.text.trim().toUpperCase(),
          description: _description.text.trim(),
          responsibleUserId: responsibleUserId,
        ),
      );
      if (mounted) {
        showPrototypeMessage(
          context,
          _editing ? 'Equipe atualizada.' : 'Equipe criada com sucesso.',
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _acronym.dispose();
    _description.dispose();
    super.dispose();
  }
}
