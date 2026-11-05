import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../studyapp/presentation/widgets/studyapp_ui.dart';
import '../domain/waitlist_repository.dart';

class WaitlistLandingView extends StatefulWidget {
  const WaitlistLandingView({required this.repository, super.key});

  final WaitlistRepository repository;

  @override
  State<WaitlistLandingView> createState() => _WaitlistLandingViewState();
}

class _WaitlistLandingViewState extends State<WaitlistLandingView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  WaitlistUsageProfile? _usageProfile;
  bool _receiveNews = false;
  bool _isSending = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
        child: ContentWidth(
          maxWidth: 1080,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _WebHeader(),
              const SizedBox(height: 64),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 780;
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(child: _WebHero()),
                        const SizedBox(width: 52),
                        Expanded(child: _formCard()),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _WebHero(),
                      const SizedBox(height: 36),
                      _formCard(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 56),
              const _TrustStrip(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formCard() {
    return GlassCard(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.all(24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        child: _sent ? _success() : _form(),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('waitlist-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Entre para a lista de interesse',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: StudyAppColors.textPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acompanhe o lançamento e ajude a construir os próximos passos do StudyApp.',
            style: TextStyle(color: StudyAppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 22),
          TextFormField(
            key: const Key('waitlist-name'),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nome',
              hintText: 'Como podemos chamar você?',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('waitlist-email'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'E-mail *',
              hintText: 'fixture-3b8efab1df@example.invalid',
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<WaitlistUsageProfile>(
            key: const Key('waitlist-profile'),
            initialValue: _usageProfile,
            decoration: const InputDecoration(
              labelText: 'Perfil de uso (opcional)',
            ),
            items: WaitlistUsageProfile.values
                .map(
                  (profile) => DropdownMenuItem(
                    value: profile,
                    child: Text(profile.label),
                  ),
                )
                .toList(),
            onChanged: _isSending
                ? null
                : (value) => setState(() => _usageProfile = value),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              key: const Key('waitlist-news'),
              value: _receiveNews,
              onChanged: _isSending
                  ? null
                  : (value) => setState(() => _receiveNews = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              visualDensity: VisualDensity.compact,
              title: const Text(
                'Quero receber novidades sobre o lançamento do StudyApp',
                style: TextStyle(
                  color: StudyAppColors.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Text(
                _errorMessage!,
                key: const Key('waitlist-error'),
                style: const TextStyle(color: StudyAppColors.danger),
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('waitlist-submit'),
            onPressed: _isSending ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            icon: _isSending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward),
            label: Text(
              _isSending ? 'Enviando...' : 'Quero conhecer o StudyApp',
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: StudyAppColors.textSecondary,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Usaremos seus dados somente para este contato, conforme nossa Política de Privacidade.',
                  style: TextStyle(
                    color: StudyAppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _success() {
    return Semantics(
      key: const Key('waitlist-success'),
      liveRegion: true,
      label: 'Interesse registrado com sucesso.',
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 38),
        child: Column(
          key: ValueKey('waitlist-confirmation'),
          children: [
            Icon(Icons.check_circle, color: StudyAppColors.success, size: 60),
            SizedBox(height: 18),
            Text(
              'Tudo certo!',
              style: TextStyle(
                color: StudyAppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Seu interesse foi registrado. Avisaremos você sobre as novidades do StudyApp.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: StudyAppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Digite um e-mail válido.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.join(
        JoinWaitlistInput(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          usageProfile: _usageProfile,
          receiveLaunchNews: _receiveNews,
        ),
      );
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

class _WebHeader extends StatelessWidget {
  const _WebHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        StudyAppLogo(),
        Spacer(),
        StatusPill(label: 'EM BREVE', color: Color(0xFF70F0A4)),
      ],
    );
  }
}

class _WebHero extends StatelessWidget {
  const _WebHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusPill(label: 'CONHEÇA O AUTH+', color: Color(0xFF70F0A4)),
        const SizedBox(height: 18),
        Text(
          'Proteja e compartilhe acessos TOTP com controle e auditoria.',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Uma forma segura de compartilhar acessos temporários sem perder visibilidade, governança ou rastreabilidade.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFFC8D7FF),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        const _HeroPoint(
          icon: Icons.shield_outlined,
          text: 'Códigos TOTP protegidos e compartilhados com segurança',
        ),
        const _HeroPoint(
          icon: Icons.rule_outlined,
          text: 'Controle de acesso alinhado às regras da sua equipe',
        ),
        const _HeroPoint(
          icon: Icons.manage_search,
          text: 'Auditoria clara para acompanhar cada utilização',
        ),
      ],
    );
  }
}

class _HeroPoint extends StatelessWidget {
  const _HeroPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF70F0A4), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2860).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(StudyAppSpacing.radiusLg),
        border: Border.all(color: const Color(0xFF1A438F)),
      ),
      child: const Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 24,
        runSpacing: 12,
        children: [
          _TrustItem(
            icon: Icons.lock_outline,
            label: 'Segurança desde a origem',
          ),
          _TrustItem(
            icon: Icons.groups_outlined,
            label: 'Feito para pessoas e equipes',
          ),
          _TrustItem(
            icon: Icons.fact_check_outlined,
            label: 'Controle com rastreabilidade',
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF8FBEFF), size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFFC8D7FF))),
      ],
    );
  }
}
