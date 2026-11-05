import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/app/app_theme.dart';
import 'package:frontend/src/features/studyapp/data/mock_studyapp_repository.dart';
import 'package:frontend/src/features/studyapp/data/secure_auth_session_store.dart';
import 'package:frontend/src/features/studyapp/domain/auth_session_store.dart';
import 'package:frontend/src/features/studyapp/domain/authentication.dart';
import 'package:frontend/src/features/studyapp/domain/studyapp_models.dart';
import 'package:frontend/src/features/studyapp/domain/studyapp_repository.dart';
import 'package:frontend/src/features/studyapp/presentation/authentication_challenge_view.dart';
import 'package:frontend/src/features/studyapp/presentation/studyapp_flow_controller.dart';
import 'package:frontend/src/features/studyapp/presentation/studyapp_root_view.dart';
import 'package:frontend/src/features/studyapp/presentation/landing_view.dart';
import 'package:frontend/src/features/studyapp/presentation/login_view.dart';
import 'package:frontend/src/features/studyapp/presentation/workspace/workspace_view.dart';

void main() {
  testWidgets('W1 login pendente termina com erro visível e recuperável', (
    tester,
  ) async {
    final pendingLogin = Completer<AuthenticationResult>();
    final authentication = _ScriptedAuthenticationRepository(
      signInHandler: (_, _) => pendingLogin.future,
    );
    final controller = _controller(authentication: authentication);
    addTearDown(controller.dispose);

    await _pumpRoot(tester, controller);
    await _openLogin(tester);
    await _submitLogin(tester);

    final submit = find.byKey(const Key('login-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(
      find.descendant(
        of: submit,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    pendingLogin.completeError(const InvalidCredentialsException());
    await tester.pump();

    expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    expect(
      find.descendant(
        of: submit,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    expect(find.byType(WorkspaceView), findsNothing);
  });

  testWidgets('W2 MFA recusado preserva a tela e cancelar retorna ao login', (
    tester,
  ) async {
    final authentication = _ScriptedAuthenticationRepository(
      signInHandler: (_, _) async => _challenge(),
      verifyMfaHandler: (_, _) async => throw const InvalidMfaCodeException(),
    );
    final sessionStore = MemoryAuthSessionStore();
    final controller = _controller(
      authentication: authentication,
      sessionStore: sessionStore,
    );
    addTearDown(controller.dispose);

    await _pumpRoot(tester, controller);
    await _openLogin(tester);
    await _submitLogin(tester);
    await _finishSwitcher(tester);

    expect(find.byType(MfaChallengeView), findsOneWidget);
    await tester.enterText(find.byKey(const Key('mfa-code')), '123456');
    await tester.tap(find.byKey(const Key('mfa-submit')));
    await tester.pump();

    expect(find.byKey(const Key('mfa-error')), findsOneWidget);
    expect(find.byType(MfaChallengeView), findsOneWidget);
    expect(sessionStore.challenge, isNotNull);
    expect(sessionStore.session, isNull);
    expect(find.byType(WorkspaceView), findsNothing);

    final cancel = find.byKey(const Key('challenge-cancel'));
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await _finishSwitcher(tester);

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.byType(LandingView), findsNothing);
    expect(find.byType(WorkspaceView), findsNothing);
    expect(sessionStore.challenge, isNull);
  });

  testWidgets('W2 challenge MFA expirado não chama verificação remota', (
    tester,
  ) async {
    final authentication = _ScriptedAuthenticationRepository(
      signInHandler: (_, _) async => _challenge(expiresAt: DateTime.utc(2000)),
      verifyMfaHandler: (_, _) async => _session,
    );
    final sessionStore = MemoryAuthSessionStore();
    final controller = _controller(
      authentication: authentication,
      sessionStore: sessionStore,
    );
    addTearDown(controller.dispose);

    await _pumpRoot(tester, controller);
    await _openLogin(tester);
    await _submitLogin(tester);
    await _finishSwitcher(tester);

    await tester.enterText(find.byKey(const Key('mfa-code')), '123456');
    await tester.tap(find.byKey(const Key('mfa-submit')));
    await tester.pump();
    await _finishSwitcher(tester);

    expect(authentication.verifyMfaCalls, 0);
    expect(find.byType(LoginView), findsOneWidget);
    expect(find.byType(WorkspaceView), findsNothing);
    expect(sessionStore.session, isNull);
    expect(sessionStore.challenge, isNull);
  });

  testWidgets('W3 login persiste, reinício retoma e logout remove sessão', (
    tester,
  ) async {
    final storage = _FakeCredentialStorage();
    final authentication = _ScriptedAuthenticationRepository(
      signInHandler: (_, _) async => _session,
    );

    final firstStore = SecureAuthSessionStore(storage: storage);
    final firstController = _controller(
      authentication: authentication,
      sessionStore: firstStore,
    );
    addTearDown(firstController.dispose);
    await _pumpRoot(tester, firstController);
    await _openLogin(tester);
    await _submitLogin(tester);
    await _finishSwitcher(tester);

    expect(find.byType(WorkspaceView), findsOneWidget);
    expect(storage.value, isNotNull);

    final secondStore = SecureAuthSessionStore(storage: storage);
    await secondStore.restoreSession();
    expect(secondStore.session, isNotNull);
    final pendingWorkspace = _PendingWorkspaceRepository();
    final secondController = _controller(
      authentication: authentication,
      sessionStore: secondStore,
      workspace: pendingWorkspace,
    );
    addTearDown(secondController.dispose);
    final resume = secondController.resumeSession();
    await pendingWorkspace.requested.future;
    await _pumpRoot(tester, secondController);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(WorkspaceView), findsNothing);

    pendingWorkspace.complete(_workspaceData);
    await resume;
    await tester.pump();
    await _finishSwitcher(tester);

    expect(pendingWorkspace.loadCalls, 1);
    expect(find.byType(WorkspaceView), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pump();
    final logout = find.text('Sair da demonstração');
    await tester.scrollUntilVisible(logout, 300);
    await tester.tap(logout);
    await tester.pump();
    await _finishSwitcher(tester);

    expect(find.byType(LandingView), findsOneWidget);
    expect(find.byType(WorkspaceView), findsNothing);
    expect(storage.value, isNull);

    final thirdStore = SecureAuthSessionStore(storage: storage);
    await thirdStore.restoreSession();
    expect(thirdStore.session, isNull);
    final thirdController = _controller(
      authentication: authentication,
      sessionStore: thirdStore,
    );
    addTearDown(thirdController.dispose);
    await thirdController.resumeSession();
    await _pumpRoot(tester, thirdController);

    expect(find.byType(LandingView), findsOneWidget);
    expect(find.byType(WorkspaceView), findsNothing);
  });

  testWidgets('W4 falha transitória na retomada oferece retry com sucesso', (
    tester,
  ) async {
    final sessionStore = MemoryAuthSessionStore()..startSession(_session);
    final workspace = _RetryWorkspaceRepository();
    final controller = _controller(
      authentication: _ScriptedAuthenticationRepository(
        signInHandler: (_, _) async => _session,
      ),
      sessionStore: sessionStore,
      workspace: workspace,
    );
    addTearDown(controller.dispose);

    final firstAttempt = controller.resumeSession();
    await workspace.firstRequested.future;
    await _pumpRoot(tester, controller);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(WorkspaceView), findsNothing);

    workspace.failFirst(StateError('synthetic transient workspace failure'));
    await firstAttempt;
    await tester.pump();

    expect(
      find.text('Não foi possível confirmar a sessão. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Tentar novamente'), findsOneWidget);
    expect(find.byType(WorkspaceView), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Tentar novamente'));
    await tester.pump();
    await _finishSwitcher(tester);

    expect(workspace.loadCalls, 2);
    expect(workspace.successfulLoads, 1);
    expect(find.byType(WorkspaceView), findsOneWidget);
  });
}

Future<void> _pumpRoot(
  WidgetTester tester,
  StudyAppFlowController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey(controller),
      theme: buildAppTheme(),
      home: StudyAppRootView(controller: controller),
    ),
  );
  await tester.pump();
}

Future<void> _openLogin(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Entrar').first);
  await tester.pump();
  await _finishSwitcher(tester);
  expect(find.byType(LoginView), findsOneWidget);
}

Future<void> _submitLogin(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  expect(fields, findsNWidgets(2));
  await tester.enterText(fields.at(0), 'fixture-b3cc0475bb@example.invalid');
  await tester.enterText(fields.at(1), 'synthetic-password');
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pump();
}

Future<void> _finishSwitcher(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 400));

StudyAppFlowController _controller({
  required AuthenticationRepository authentication,
  AuthSessionStore? sessionStore,
  StudyAppRepository? workspace,
}) => StudyAppFlowController(
  repository: workspace ?? _ImmediateWorkspaceRepository(),
  authenticationRepository: authentication,
  sessionStore: sessionStore ?? MemoryAuthSessionStore(),
);

final _session = AuthenticatedSession(
  accessToken: _accessToken(),
  tokenType: 'Bearer',
  expiresAt: DateTime.utc(2099),
);

AuthenticationChallenge _challenge({DateTime? expiresAt}) =>
    AuthenticationChallenge(
      type: AuthChallengeType.mfaRequired,
      challengeToken: 'synthetic-mfa-challenge',
      expiresAt: expiresAt ?? DateTime.utc(2099),
    );

String _accessToken() {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'RS256', 'typ': 'JWT'})}.'
      '${encode({'token_use': 'ACCESS', 'aud': 'studyapp-api'})}.signature';
}

typedef _SignInHandler =
    Future<AuthenticationResult> Function(String email, String password);
typedef _VerifyMfaHandler =
    Future<AuthenticatedSession> Function(String challengeToken, String code);

class _ScriptedAuthenticationRepository implements AuthenticationRepository {
  _ScriptedAuthenticationRepository({
    required this.signInHandler,
    this.verifyMfaHandler,
  });

  final _SignInHandler signInHandler;
  final _VerifyMfaHandler? verifyMfaHandler;
  int verifyMfaCalls = 0;

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) => signInHandler(email, password);

  @override
  Future<AuthenticatedSession> verifyMfa({
    required String challengeToken,
    required String code,
  }) {
    verifyMfaCalls += 1;
    final handler = verifyMfaHandler;
    if (handler == null) {
      throw UnsupportedError('MFA verification not configured');
    }
    return handler(challengeToken, code);
  }

  @override
  Future<List<RequiredPolicy>> findCurrentPolicies() =>
      throw UnsupportedError('Policies not expected');

  @override
  Future<List<RequiredPolicy>> findPendingPolicies({
    required String challengeToken,
  }) => throw UnsupportedError('Pending policies not expected');

  @override
  Future<AuthenticationResult> acceptRequiredPolicies({
    required String challengeToken,
    required Set<String> policyVersionIds,
  }) => throw UnsupportedError('Policy acceptance not expected');

  @override
  Future<void> requestPasswordRecovery({required String email}) =>
      throw UnsupportedError('Password recovery not expected');

  @override
  Future<void> previewPasswordRecovery({required String token}) =>
      throw UnsupportedError('Password recovery preview not expected');

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) => throw UnsupportedError('Password reset not expected');

  @override
  Future<void> changePassword({
    required String accessToken,
    required String tokenType,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) => throw UnsupportedError('Password change not expected');
}

class _FakeCredentialStorage implements SessionCredentialStorage {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;

  @override
  Future<void> delete() async => value = null;
}

class _PendingWorkspaceRepository extends MockStudyAppRepository {
  final requested = Completer<void>();
  final _result = Completer<WorkspaceData>();
  int loadCalls = 0;

  @override
  Future<WorkspaceData> loadWorkspace() {
    loadCalls += 1;
    if (!requested.isCompleted) requested.complete();
    return _result.future;
  }

  void complete(WorkspaceData workspace) => _result.complete(workspace);
}

class _ImmediateWorkspaceRepository extends MockStudyAppRepository {
  @override
  Future<WorkspaceData> loadWorkspace() async => _workspaceData;
}

class _RetryWorkspaceRepository extends MockStudyAppRepository {
  final firstRequested = Completer<void>();
  final _firstResult = Completer<WorkspaceData>();
  int loadCalls = 0;
  int successfulLoads = 0;

  @override
  Future<WorkspaceData> loadWorkspace() async {
    loadCalls += 1;
    if (loadCalls == 1) {
      if (!firstRequested.isCompleted) firstRequested.complete();
      return _firstResult.future;
    }
    successfulLoads += 1;
    return _workspaceData;
  }

  void failFirst(Object error) => _firstResult.completeError(error);
}

final _workspaceResource = ProtectedResource(
  id: 'synthetic-resource',
  name: 'Synthetic Resource',
  description: 'Synthetic workspace fixture',
  team: 'Synthetic Team',
  category: 'Test',
  risk: ResourceRisk.moderate,
  provisioning: 'Synthetic',
  vaultLabel: 'Synthetic Vault',
  lastAccessLabel: 'Never',
  iconLabel: 'SR',
);

final _workspaceData = WorkspaceData(
  dashboard: const DashboardData(
    userName: 'Synthetic',
    resourceCount: 1,
    activeDelegations: 0,
    pendingRequests: 0,
    alertCount: 0,
    recentEvents: [],
  ),
  resources: [_workspaceResource],
  auditEvents: const [],
  pendingRequest: AccessRequest(
    id: 'synthetic-request',
    resource: _workspaceResource,
    requester: 'Synthetic User',
    justification: 'Synthetic test fixture',
    accessType: 'Synthetic',
    durationMinutes: 5,
    priority: 'Low',
    requestedAt: DateTime.utc(2026, 11, 3),
  ),
  profile: const UserProfile(
    fullName: 'Synthetic User',
    email: 'fixture-b3cc0475bb@example.invalid',
    organization: 'Synthetic Organization',
    team: 'Synthetic Team',
    role: 'Tester',
    phone: '+55 00 00000-0000',
    twoFactorEnabled: true,
    vaultType: VaultType.studyApp,
    canInviteTeamUsers: false,
    canManageTeams: false,
  ),
  teams: const [],
  members: const [],
  invitations: const [],
);
