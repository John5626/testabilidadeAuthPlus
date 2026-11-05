import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/studyapp_models.dart';
import 'widgets/studyapp_ui.dart';

class FirstAccessView extends StatefulWidget {
  const FirstAccessView({
    required this.isBusy,
    required this.errorMessage,
    required this.onComplete,
    super.key,
  });

  final bool isBusy;
  final String? errorMessage;
  final Future<bool> Function(FirstAccessSetup setup) onComplete;

  @override
  State<FirstAccessView> createState() => _FirstAccessViewState();
}

class _FirstAccessViewState extends State<FirstAccessView> {
  final _phone = TextEditingController();
  final _jobTitle = TextEditingController(text: 'Administrador de TI');
  final _verificationCode = TextEditingController();
  final _vaultName = TextEditingController();
  final _vaultEndpoint = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _step = 0;
  var _termsAccepted = false;
  var _twoFactorVerified = false;
  var _vaultType = VaultType.studyApp;

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: ContentWidth(
        maxWidth: 680,
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(
                        'Prepare seu ambiente',
                        subtitle:
                            'Complete as configurações essenciais antes de acessar o StudyApp.',
                      ),
                      const SizedBox(height: 18),
                      _progress(),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: GlassCard(
                          key: ValueKey(_step),
                          color: Colors.white,
                          padding: const EdgeInsets.all(20),
                          child: _content(),
                        ),
                      ),
                      if (widget.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.errorMessage!,
                          style: const TextStyle(color: Color(0xFFFFA7B1)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: Key('first-access-next-$_step'),
                        onPressed: widget.isBusy ? null : _next,
                        icon: Icon(
                          _step == 3
                              ? Icons.rocket_launch_outlined
                              : Icons.arrow_forward,
                        ),
                        label: widget.isBusy
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _step == 3
                                    ? 'Acessar meu ambiente'
                                    : 'Continuar',
                              ),
                      ),
                      if (_step > 0)
                        TextButton(
                          onPressed: widget.isBusy
                              ? null
                              : () => setState(() => _step -= 1),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFC8D7FF),
                          ),
                          child: const Text('Voltar'),
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

  Widget _progress() {
    const labels = ['Perfil', 'Termos', '2 etapas', 'Cofre'];
    return Row(
      children: List.generate(
        labels.length,
        (index) => Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: index <= _step
                    ? StudyAppColors.accent
                    : Colors.white24,
                child: index < _step
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
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

  Widget _content() => switch (_step) {
    0 => _profileStep(),
    1 => _termsStep(),
    2 => _twoFactorStep(),
    _ => _vaultStep(),
  };

  Widget _profileStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        Icons.badge_outlined,
        'Complete seu perfil',
        'Essas informações ajudam nas aprovações e na auditoria.',
      ),
      const SizedBox(height: 18),
      TextFormField(
        controller: _phone,
        decoration: const InputDecoration(
          labelText: 'Telefone',
          prefixIcon: Icon(Icons.phone_outlined),
        ),
        keyboardType: TextInputType.phone,
        validator: _required,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _jobTitle,
        decoration: const InputDecoration(
          labelText: 'Cargo/Função',
          prefixIcon: Icon(Icons.work_outline),
        ),
        validator: _required,
      ),
    ],
  );

  Widget _termsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        Icons.policy_outlined,
        'Termos e políticas vigentes',
        'Versão 1.0 • publicada em 15/07/2026',
      ),
      const SizedBox(height: 16),
      Container(
        height: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: StudyAppColors.background,
          border: Border.all(color: StudyAppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const SingleChildScrollView(
          child: Text(
            'Ao usar o StudyApp, você concorda com o tratamento dos dados necessários à gestão de identidade, aplicação das políticas de acesso e registro de eventos auditáveis. Segredos e códigos TOTP não são persistidos em texto puro pela aplicação. A organização é responsável por definir seus escopos, aprovadores e períodos de retenção.\n\nO aceite registra usuário, versão, data, hora e origem da confirmação.',
          ),
        ),
      ),
      const SizedBox(height: 10),
      CheckboxListTile(
        value: _termsAccepted,
        onChanged: (value) => setState(() => _termsAccepted = value ?? false),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text('Li e aceito a versão vigente.'),
      ),
    ],
  );

  Widget _twoFactorStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        Icons.phonelink_lock_outlined,
        'Proteja o acesso em duas etapas',
        'Use seu aplicativo autenticador para ler a chave de demonstração.',
      ),
      const SizedBox(height: 16),
      Center(
        child: Container(
          width: 156,
          height: 156,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: StudyAppColors.navy, width: 5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomPaint(painter: _MockQrPainter()),
        ),
      ),
      const SizedBox(height: 10),
      const SelectableText(
        'STUDYAPP-DEMO-JBSWY3DPEHPK3PXP',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 14),
      TextFormField(
        key: const Key('two-factor-code'),
        controller: _verificationCode,
        decoration: InputDecoration(
          labelText: 'Código de 6 dígitos',
          prefixIcon: const Icon(Icons.pin_outlined),
          suffixIcon: _twoFactorVerified
              ? const Icon(Icons.check_circle, color: StudyAppColors.success)
              : null,
        ),
        keyboardType: TextInputType.number,
        maxLength: 6,
        onChanged: (value) =>
            setState(() => _twoFactorVerified = value == '482931'),
        validator: (value) =>
            value == '482931' ? null : 'Para a demonstração, use 482931.',
      ),
      const Text(
        'Código de demonstração: 482931',
        style: TextStyle(color: StudyAppColors.textSecondary, fontSize: 12),
      ),
    ],
  );

  Widget _vaultStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        Icons.inventory_2_outlined,
        'Onde seus segredos ficarão?',
        'O StudyApp armazena referências seguras; você escolhe quem gerencia o cofre.',
      ),
      const SizedBox(height: 16),
      _vaultOption(
        type: VaultType.studyApp,
        icon: Icons.verified_user_outlined,
        title: 'Cofre gerenciado StudyApp',
        subtitle:
            'Configuração imediata, criptografia e disponibilidade gerenciadas pelo sistema.',
        badge: 'Recomendado para começar',
      ),
      const SizedBox(height: 10),
      _vaultOption(
        type: VaultType.organization,
        icon: Icons.account_balance_outlined,
        title: 'Cofre da organização',
        subtitle:
            'Integre o cofre que sua equipe já utiliza e mantenha a governança interna.',
        badge: 'Mais controle',
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        child: _vaultType == VaultType.organization
            ? Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _vaultName,
                      decoration: const InputDecoration(
                        labelText: 'Nome da integração',
                        hintText: 'Vault Corporativo',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _vaultEndpoint,
                      decoration: const InputDecoration(
                        labelText: 'Endpoint do cofre',
                        hintText: 'https://vault.empresa.com',
                        prefixIcon: Icon(Icons.link),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nenhuma credencial será salva nesta demonstração. A API deverá concluir a autenticação com o provedor.',
                      style: TextStyle(
                        color: StudyAppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );

  Widget _vaultOption({
    required VaultType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
  }) {
    final selected = _vaultType == type;
    return InkWell(
      onTap: () => setState(() => _vaultType = type),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F0FF) : Colors.white,
          border: Border.all(
            color: selected ? StudyAppColors.accent : StudyAppColors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? StudyAppColors.accent
                  : StudyAppColors.textSecondary,
            ),
            Icon(icon, color: StudyAppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: StudyAppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  StatusPill(
                    label: badge,
                    color: selected
                        ? StudyAppColors.accent
                        : StudyAppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(IconData icon, String title, String subtitle) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        backgroundColor: const Color(0xFFE8F0FF),
        foregroundColor: StudyAppColors.accent,
        child: Icon(icon),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: StudyAppColors.textSecondary),
            ),
          ],
        ),
      ),
    ],
  );

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Campo obrigatório.' : null;

  Future<void> _next() async {
    if (_step == 0 && !(_formKey.currentState?.validate() ?? false)) return;
    if (_step == 1 && !_termsAccepted) {
      showPrototypeMessage(
        context,
        'Aceite os termos vigentes para continuar.',
      );
      return;
    }
    if (_step == 2 && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_step < 3) {
      setState(() => _step += 1);
      return;
    }
    if (_vaultType == VaultType.organization &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await widget.onComplete(
      FirstAccessSetup(
        phone: _phone.text.trim(),
        jobTitle: _jobTitle.text.trim(),
        termsAccepted: _termsAccepted,
        twoFactorEnabled: _twoFactorVerified,
        vaultType: _vaultType,
        vaultName: _vaultName.text.trim(),
        vaultEndpoint: _vaultEndpoint.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _phone,
      _jobTitle,
      _verificationCode,
      _vaultName,
      _vaultEndpoint,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}

class _MockQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF071B45);
    const cells = 17;
    final cell = size.width / cells;
    for (var row = 0; row < cells; row++) {
      for (var col = 0; col < cells; col++) {
        final filled =
            ((row * 7 + col * 11 + row * col) % 5 < 2) ||
            (row < 5 && col < 5) ||
            (row < 5 && col > 11) ||
            (row > 11 && col < 5);
        if (filled) {
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell, cell),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
