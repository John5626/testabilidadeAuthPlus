import 'package:flutter/material.dart';
import '../../../../core/security/temporary_clipboard.dart';

import '../../../../app/app_theme.dart';
import '../../domain/studyapp_models.dart';
import '../widgets/studyapp_ui.dart';
import 'workspace_view_model.dart';

class InviteTeamUserView extends StatefulWidget {
  const InviteTeamUserView({
    required this.viewModel,
    required this.team,
    super.key,
  });

  final WorkspaceViewModel viewModel;
  final OrganizationTeam team;

  @override
  State<InviteTeamUserView> createState() => _InviteTeamUserViewState();
}

class _InviteTeamUserViewState extends State<InviteTeamUserView> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  var _step = 0;
  var _teamRole = 'Membro';
  final _profiles = <String>{'Membro equipe'};
  TeamInvitationReceipt? _receipt;
  var _tokenVisible = true;
  String? _errorMessage;
  OrganizationMember? _reactivationMember;

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: ContentWidth(
        maxWidth: 640,
        child: Column(
          children: [
            AppTopBar(onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: _receipt == null ? _formContent() : _successContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            'Convidar usuário',
            subtitle:
                'Equipe ${widget.team.name} • o usuário definirá a própria senha.',
          ),
          const SizedBox(height: 14),
          _progress(),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: GlassCard(
              key: ValueKey(_step),
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: switch (_step) {
                0 => _personStep(),
                1 => _accessStep(),
                _ => _reviewStep(),
              },
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFFFA7B1)),
            ),
            if (_reactivationMember != null) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                key: const Key('reactivate-existing-member'),
                onPressed: widget.viewModel.isBusy ? null : _reactivateMember,
                icon: const Icon(Icons.restore_outlined),
                label: const Text('Reativar vínculo existente'),
              ),
            ],
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            key: Key('invite-next-$_step'),
            onPressed: widget.viewModel.isBusy ? null : _next,
            icon: Icon(_step == 2 ? Icons.send_outlined : Icons.arrow_forward),
            label: widget.viewModel.isBusy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_step == 2 ? 'Enviar convite' : 'Continuar'),
          ),
          if (_step > 0)
            TextButton(
              onPressed: () => setState(() => _step -= 1),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC8D7FF),
              ),
              child: const Text('Voltar'),
            ),
        ],
      ),
    );
  }

  Widget _progress() {
    const labels = ['Pessoa', 'Acesso', 'Confirmar'];
    return Row(
      children: List.generate(
        labels.length,
        (index) => Expanded(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index <= _step
                      ? StudyAppColors.accentSoft
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(500),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                labels[index],
                style: TextStyle(
                  color: index <= _step ? Colors.white : Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _personStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(Icons.person_add_alt_1, 'Dados do convidado'),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('invite-first-name'),
          controller: _firstName,
          decoration: const InputDecoration(
            labelText: 'Nome',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: _required,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('invite-last-name'),
          controller: _lastName,
          decoration: const InputDecoration(
            labelText: 'Sobrenome',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('invite-email'),
          controller: _email,
          decoration: const InputDecoration(
            labelText: 'E-mail institucional',
            prefixIcon: Icon(Icons.mail_outline),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) =>
              (value ?? '').contains('@') ? null : 'Informe um e-mail válido.',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, color: StudyAppColors.accent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'O convidado receberá por e-mail um link de uso único válido por 72 horas para concluir a conta e entrar na equipe.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _accessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(Icons.admin_panel_settings_outlined, 'Papel e perfis'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _teamRole,
          decoration: const InputDecoration(
            labelText: 'Papel na equipe',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          items: ['Membro', 'Aprovador de Recursos', 'Responsável']
              .map((role) => DropdownMenuItem(value: role, child: Text(role)))
              .toList(),
          onChanged: (value) => setState(() => _teamRole = value!),
        ),
        const SizedBox(height: 14),
        const Text(
          'Perfis permitidos',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              ['Membro equipe', 'Aprovador equipe', 'Admin equipe', 'Auditor']
                  .map(
                    (profile) => FilterChip(
                      label: Text(profile),
                      selected: _profiles.contains(profile),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _profiles.add(profile);
                          } else if (_profiles.length > 1) {
                            _profiles.remove(profile);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 12),
        const Text(
          'O perfil Admin sistema não está disponível porque está acima da alçada do Admin equipe.',
          style: TextStyle(color: StudyAppColors.textSecondary, fontSize: 12),
        ),
        const Divider(height: 26),
        const Text(
          'O próprio convidado confirmará o tratamento de seus dados ao concluir o convite.',
          style: TextStyle(color: StudyAppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _reviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(Icons.fact_check_outlined, 'Revise o convite'),
        const SizedBox(height: 16),
        _reviewLine('Nome', '${_firstName.text} ${_lastName.text}'.trim()),
        _reviewLine('E-mail', _email.text),
        _reviewLine('Equipe', widget.team.name),
        _reviewLine('Papel', _teamRole),
        _reviewLine('Perfis', _profiles.join(', ')),
        const Divider(height: 26),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.schedule, color: StudyAppColors.accent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'O convite expira em 72 horas. O usuário permanecerá pendente até definir a senha e aceitar os termos vigentes.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _successContent() {
    final receipt = _receipt!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          'Convite criado',
          subtitle: 'O link para concluir a conta foi enviado por e-mail.',
        ),
        const SizedBox(height: 16),
        GlassCard(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFE8F0FF),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  color: StudyAppColors.accent,
                  size: 34,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${receipt.member.fullName} foi convidado',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                receipt.member.email,
                textAlign: TextAlign.center,
                style: const TextStyle(color: StudyAppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: StudyAppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: StudyAppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tokenVisible
                            ? receipt.oneTimeToken
                            : '••••••••••••••••••••••••••',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      tooltip: _tokenVisible
                          ? 'Ocultar token'
                          : 'Mostrar token',
                      onPressed: () {
                        setState(() => _tokenVisible = !_tokenVisible);
                      },
                      icon: Icon(
                        _tokenVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _copyToken(receipt.oneTimeToken),
                icon: const Icon(Icons.copy),
                label: const Text('Copiar token de contingência'),
              ),
              const SizedBox(height: 10),
              const Text(
                'O token de contingência aparece apenas neste retorno e não foi salvo pelo aplicativo. O e-mail foi enviado automaticamente. Expiração: 72 horas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: StudyAppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
          child: const Text('Voltar para a equipe'),
        ),
      ],
    );
  }

  Widget _heading(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: StudyAppColors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _reviewLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: StudyAppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    return (value ?? '').trim().isEmpty ? 'Campo obrigatório.' : null;
  }

  Future<void> _next() async {
    _errorMessage = null;
    _reactivationMember = null;
    if (_step == 0 && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }

    try {
      final receipt = await widget.viewModel.inviteTeamUser(
        InviteTeamUserInput(
          teamId: widget.team.id,
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim().isEmpty
              ? null
              : _lastName.text.trim(),
          email: _email.text.trim(),
          teamRole: _teamRole,
          profiles: _profiles,
        ),
      );
      if (mounted) {
        setState(() => _receipt = receipt);
      }
    } catch (error) {
      if (mounted) {
        final normalizedEmail = _email.text.trim().toLowerCase();
        final inactiveMember = widget.viewModel.data.members
            .where(
              (member) =>
                  member.teamId == widget.team.id &&
                  member.email.toLowerCase() == normalizedEmail &&
                  member.status == TeamMemberStatus.inactive,
            )
            .firstOrNull;
        setState(() {
          _reactivationMember = inactiveMember;
          _errorMessage = inactiveMember == null
              ? error.toString()
              : 'Esta pessoa já pertenceu à equipe. Reative o vínculo existente para preservar o histórico.';
        });
      }
    }
  }

  Future<void> _reactivateMember() async {
    final member = _reactivationMember;
    if (member == null) return;
    await widget.viewModel.setTeamUserStatus(member, TeamMemberStatus.active);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _copyToken(String token) async {
    await copySensitiveTextTemporarily(token);
    if (mounted) {
      showPrototypeMessage(
        context,
        'Convite copiado. O app tentará limpar a área de transferência após 60 segundos se o conteúdo não mudar.',
      );
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _receipt = null;
    super.dispose();
  }
}
