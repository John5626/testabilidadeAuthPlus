import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class StudyAppLogo extends StatelessWidget {
  const StudyAppLogo({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo/icon.png',
          width: compact ? 42 : 54,
          height: compact ? 42 : 54,
          errorBuilder: (_, _, _) => Icon(
            Icons.shield_outlined,
            size: compact ? 38 : 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Auth +',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            if (!compact)
              Text(
                'Segurança • Controle • Auditoria',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class NavyPage extends StatelessWidget {
  const NavyPage({required this.child, this.bottomNavigationBar, super.key});

  final Widget child;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudyAppColors.navy,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A2E70), StudyAppColors.navyDeep],
          ),
        ),
        child: SafeArea(child: child),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class ContentWidth extends StatelessWidget {
  const ContentWidth({required this.child, this.maxWidth = 720, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF0D2D6A).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(StudyAppSpacing.radiusLg),
        border: Border.all(
          color: const Color(0xFF3478DC).withValues(alpha: 0.58),
        ),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFC8D7FF),
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(500),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({this.onBack, this.actions = const [], super.key});

  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton.filledTonal(
              tooltip: 'Voltar',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 10),
          ],
          const StudyAppLogo(compact: true),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

void showPrototypeMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
