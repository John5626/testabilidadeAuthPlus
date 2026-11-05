import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/di/app_dependencies.dart';
import '../core/navigation/invitation_deep_link.dart';
import '../core/navigation/password_recovery_deep_link.dart';
import '../core/navigation/browser_navigation.dart';
import '../features/studyapp/presentation/studyapp_flow_controller.dart';
import '../features/studyapp/presentation/studyapp_root_view.dart';
import '../features/waitlist/presentation/waitlist_landing_view.dart';
import 'app_theme.dart';

class StudyAppApp extends StatefulWidget {
  const StudyAppApp({
    required this.dependencies,
    this.webOnly = kIsWeb,
    this.initialRoute,
    super.key,
  });

  final AppDependencies dependencies;
  final bool webOnly;
  final String? initialRoute;

  @override
  State<StudyAppApp> createState() => _StudyAppAppState();
}

class _StudyAppAppState extends State<StudyAppApp> {
  late final StudyAppFlowController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StudyAppFlowController(
      repository: widget.dependencies.studyAppRepository,
      publicRegistrationRepository:
          widget.dependencies.publicRegistrationRepository,
      authenticationRepository: widget.dependencies.authenticationRepository,
      sessionStore: widget.dependencies.authSessionStore,
    );
    if (!widget.webOnly &&
        !isPasswordRecoveryRoute(widget.initialRoute) &&
        invitationTokenFromRoute(widget.initialRoute) == null) {
      _controller.resumeSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyApp',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: widget.initialRoute,
      onGenerateRoute: _generateDeepLinkRoute,
      home: widget.webOnly
          ? WaitlistLandingView(
              repository: widget.dependencies.waitlistRepository,
            )
          : StudyAppRootView(controller: _controller),
    );
  }

  Route<void>? _generateDeepLinkRoute(RouteSettings settings) {
    if (isPasswordRecoveryRoute(settings.name)) {
      final recoveryToken = passwordRecoveryTokenFromRoute(settings.name);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (recoveryToken == null) {
          _controller.openInvalidPasswordRecoveryLink();
        } else {
          _controller.openPasswordRecoveryFromLink(recoveryToken);
        }
        if (widget.webOnly) clearPasswordRecoveryTokenFromBrowserUrl();
      });
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => StudyAppRootView(controller: _controller),
      );
    }
    final token = invitationTokenFromRoute(settings.name);
    if (token == null) return null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.openInvitationFromLink(token);
      if (widget.webOnly) clearInvitationTokenFromBrowserUrl();
    });
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => StudyAppRootView(
        controller: _controller,
        webInvitationFlow: widget.webOnly,
        onInvitationAccepted: widget.webOnly ? _openPlatformStore : null,
      ),
    );
  }

  Future<void> _openPlatformStore() async {
    await openPlatformStore(
      androidStoreUrl: widget.dependencies.config.androidStoreUrl,
      iosStoreUrl: widget.dependencies.config.iosStoreUrl,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
