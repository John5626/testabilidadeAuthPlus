import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import 'widgets/studyapp_ui.dart';

class LandingView extends StatefulWidget {
  const LandingView({
    required this.onCreateAccount,
    required this.onLogin,
    required this.onAcceptInvitation,
    required this.onExploreDemo,
    super.key,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;
  final VoidCallback onAcceptInvitation;
  final VoidCallback onExploreDemo;

  @override
  State<LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<LandingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion == _reduceMotion && _animation.isAnimating) {
      return;
    }

    _reduceMotion = reduceMotion;

    if (_reduceMotion) {
      _animation
        ..stop()
        ..value = 0;
    } else if (!_animation.isAnimating) {
      _animation.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavyPage(
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _LandingGlowPainter(
                        _reduceMotion ? 0 : _animation.value,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          ContentWidth(
            maxWidth: 1020,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 760;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(wide: wide),
                        SizedBox(height: wide ? 72 : 48),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _heroCopy(wide: true)),
                              const SizedBox(width: 48),
                              Expanded(child: _animatedSecurityCard()),
                            ],
                          )
                        else ...[
                          _heroCopy(wide: false),
                          const SizedBox(height: 34),
                          _animatedSecurityCard(),
                        ],
                        const SizedBox(height: 48),
                        Text(
                          'Uma camada de confiança para cada acesso',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 18),
                        _benefits(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header({required bool wide}) {
    return Row(
      children: [
        StudyAppLogo(compact: !wide),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Entrar em uma conta existente',
          child: TextButton(
            onPressed: widget.onLogin,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Entrar'),
          ),
        ),
      ],
    );
  }

  Widget _heroCopy({required bool wide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusPill(
          label: 'GESTÃO DE SEGREDOS SEM ATRITO',
          color: Color(0xFF70F0A4),
        ),
        const SizedBox(height: 18),
        Text(
          wide
              ? 'Acesso seguro,\nsem perder o controle.'
              : 'Acesso seguro, sem perder o controle.',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Centralize credenciais e códigos TOTP, aplique aprovações e acompanhe cada ação em uma trilha auditável.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFFC8D7FF),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            Semantics(
              button: true,
              label: 'Começar gratuitamente e criar uma organização',
              child: FilledButton.icon(
                key: const Key('landing-create-account'),
                onPressed: widget.onCreateAccount,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Começar gratuitamente'),
              ),
            ),
            Semantics(
              button: true,
              label: 'Abrir um convite recebido para uma equipe',
              child: OutlinedButton.icon(
                key: const Key('landing-accept-invitation'),
                onPressed: widget.onAcceptInvitation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  side: const BorderSide(color: Color(0xFF8FBEFF)),
                ),
                icon: const Icon(Icons.mark_email_read_outlined),
                label: const Text('Recebi um convite'),
              ),
            ),
            Semantics(
              button: true,
              label: 'Explorar uma demonstração com dados fictícios',
              child: OutlinedButton.icon(
                onPressed: widget.onExploreDemo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  side: const BorderSide(color: Color(0xFF8FBEFF)),
                ),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Explorar demonstração'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          label:
              'A demonstração utiliza dados fictícios e não altera nenhuma configuração.',
          child: ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Color(0xFF70F0A4),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Explore com dados fictícios. Nenhuma configuração será alterada.',
                    style: TextStyle(color: Color(0xFFC8D7FF)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _animatedSecurityCard() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final pulse = _reduceMotion
            ? 1.0
            : 1 + math.sin(_animation.value * math.pi * 2) * 0.012;

        return Transform.scale(scale: pulse, child: child);
      },
      child: Semantics(
        container: true,
        label:
            'Exemplo de acesso temporário aprovado para AWS Produção. Código demonstrativo parcialmente oculto.',
        child: ExcludeSemantics(
          child: GlassCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        StudyAppColors.accentSoft,
                        StudyAppColors.accent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: StudyAppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 26,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 46,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'AWS Produção',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Acesso temporário aprovado',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFC8D7FF)),
                ),
                const SizedBox(height: 18),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _demoCode.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 30,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10377E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2757A4)),
                        ),
                        child: Text(
                          _demoCode[index],
                          style: TextStyle(
                            color: _demoCode[index] == '•'
                                ? const Color(0xFF9EB3E0)
                                : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2F6B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1A438F)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.visibility_off_outlined,
                        size: 18,
                        color: Color(0xFF70F0A4),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Código demonstrativo com ocultação automática.',
                          style: TextStyle(
                            color: Color(0xFFC8D7FF),
                            fontSize: 12,
                          ),
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
    );
  }

  Widget _benefits() {
    const benefits = [
      (
        Icons.inventory_2_outlined,
        'Cofre flexível',
        'Use o cofre StudyApp ou integre o cofre da sua organização.',
      ),
      (
        Icons.fact_check_outlined,
        'Aprovação inteligente',
        'Defina políticas, prazos e justificativas em um fluxo simples.',
      ),
      (
        Icons.manage_search,
        'Auditoria completa',
        'Cada acesso gera evidências claras, rastreáveis e pesquisáveis.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = _benefitCardWidth(constraints.maxWidth);

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: benefits.map((item) {
            return Semantics(
              container: true,
              label: '${item.$2}. ${item.$3}',
              child: ExcludeSemantics(
                child: Container(
                  width: cardWidth,
                  constraints: const BoxConstraints(minHeight: 132),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2860).withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(
                      StudyAppSpacing.radiusLg,
                    ),
                    border: Border.all(color: const Color(0xFF1A438F)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF123A7E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.$1, color: const Color(0xFF70F0A4)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.$3,
                              style: const TextStyle(
                                color: Color(0xFFC8D7FF),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  double _benefitCardWidth(double availableWidth) {
    if (availableWidth < 600) {
      return availableWidth;
    }

    if (availableWidth < 900) {
      return (availableWidth - 12) / 2;
    }

    return (availableWidth - 24) / 3;
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }
}

const _demoCode = ['4', '8', '•', '•', '3', '1'];

class _LandingGlowPainter extends CustomPainter {
  const _LandingGlowPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2563EB).withValues(alpha: 0.20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 170));

    final x = size.width * (0.72 + math.sin(progress * math.pi * 2) * 0.06);
    final y = size.height * (0.25 + math.cos(progress * math.pi * 2) * 0.04);

    canvas.drawCircle(Offset(x, y), 170, paint);
  }

  @override
  bool shouldRepaint(covariant _LandingGlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
