import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/studyapp/data/mock_studyapp_repository.dart';
import 'package:frontend/src/features/studyapp/domain/auth_session_store.dart';
import 'package:frontend/src/features/studyapp/domain/authentication.dart';
import 'package:frontend/src/features/studyapp/domain/studyapp_models.dart';
import 'package:frontend/src/features/studyapp/presentation/studyapp_flow_controller.dart';

void main() {
  test('C6a sucesso de login obsoleto não reabre fluxo abandonado', () async {
    final result = Completer<AuthenticationResult>();
    final sessionStore = MemoryAuthSessionStore();
    final controller = StudyAppFlowController(
      repository: MockStudyAppRepository(),
      authenticationRepository: _PendingAuthenticationRepository(result),
      sessionStore: sessionStore,
    );

    controller.openLogin();
    final pendingSignIn = controller.signIn(
      email: 'fixture-b3cc0475bb@example.invalid',
      password: 'synthetic-password',
    );
    controller.openLanding();
    result.complete(
      AuthenticatedSession(
        accessToken: 'obsolete-access-token',
        tokenType: 'Bearer',
        expiresAt: DateTime.utc(2099),
      ),
    );
    final success = await pendingSignIn;

    expect(success, isFalse);
    expect(controller.stage, StudyAppStage.landing);
    expect(controller.workspace, isNull);
    expect(sessionStore.session, isNull);
  });

  test('C6b erro de login obsoleto não contamina o novo fluxo', () async {
    final result = Completer<AuthenticationResult>();
    final sessionStore = MemoryAuthSessionStore();
    final controller = StudyAppFlowController(
      repository: MockStudyAppRepository(),
      authenticationRepository: _PendingAuthenticationRepository(result),
      sessionStore: sessionStore,
    );

    controller.openLogin();
    final pendingSignIn = controller.signIn(
      email: 'fixture-b3cc0475bb@example.invalid',
      password: 'synthetic-password',
    );
    controller.openLanding();
    result.completeError(const InvalidCredentialsException());
    final success = await pendingSignIn;

    expect(success, isFalse);
    expect(controller.stage, StudyAppStage.landing);
    expect(controller.errorMessage, isNull);
    expect(sessionStore.session, isNull);
  });

  test('C6c workspace obsoleto não reabre fluxo abandonado', () async {
    final sessionStore = MemoryAuthSessionStore();
    final workspaceRepository = _PendingWorkspaceRepository();
    final controller = StudyAppFlowController(
      repository: workspaceRepository,
      authenticationRepository: _ImmediateAuthenticationRepository(),
      sessionStore: sessionStore,
    );

    controller.openLogin();
    final pendingSignIn = controller.signIn(
      email: 'fixture-b3cc0475bb@example.invalid',
      password: 'synthetic-password',
    );
    await workspaceRepository.requested.future;
    controller.openLanding();
    await workspaceRepository.complete();
    final success = await pendingSignIn;

    expect(success, isFalse);
    expect(controller.stage, StudyAppStage.landing);
    expect(controller.workspace, isNull);
    expect(sessionStore.session, isNull);
  });
}

class _PendingAuthenticationRepository implements AuthenticationRepository {
  _PendingAuthenticationRepository(this.result);

  final Completer<AuthenticationResult> result;

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) => result.future;

  @override
  Future<List<RequiredPolicy>> findCurrentPolicies() =>
      throw UnimplementedError();

  @override
  Future<List<RequiredPolicy>> findPendingPolicies({
    required String challengeToken,
  }) => throw UnimplementedError();

  @override
  Future<AuthenticationResult> acceptRequiredPolicies({
    required String challengeToken,
    required Set<String> policyVersionIds,
  }) => throw UnimplementedError();

  @override
  Future<AuthenticatedSession> verifyMfa({
    required String challengeToken,
    required String code,
  }) => throw UnimplementedError();

  @override
  Future<void> requestPasswordRecovery({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> previewPasswordRecovery({required String token}) =>
      throw UnimplementedError();

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) => throw UnimplementedError();

  @override
  Future<void> changePassword({
    required String accessToken,
    required String tokenType,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) => throw UnimplementedError();
}

class _ImmediateAuthenticationRepository implements AuthenticationRepository {
  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) async => AuthenticatedSession(
    accessToken: 'synthetic-access-token',
    tokenType: 'Bearer',
    expiresAt: DateTime.utc(2099),
  );

  @override
  Future<List<RequiredPolicy>> findCurrentPolicies() =>
      throw UnimplementedError();

  @override
  Future<List<RequiredPolicy>> findPendingPolicies({
    required String challengeToken,
  }) => throw UnimplementedError();

  @override
  Future<AuthenticationResult> acceptRequiredPolicies({
    required String challengeToken,
    required Set<String> policyVersionIds,
  }) => throw UnimplementedError();

  @override
  Future<AuthenticatedSession> verifyMfa({
    required String challengeToken,
    required String code,
  }) => throw UnimplementedError();

  @override
  Future<void> requestPasswordRecovery({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> previewPasswordRecovery({required String token}) =>
      throw UnimplementedError();

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) => throw UnimplementedError();

  @override
  Future<void> changePassword({
    required String accessToken,
    required String tokenType,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) => throw UnimplementedError();
}

class _PendingWorkspaceRepository extends MockStudyAppRepository {
  final requested = Completer<void>();
  final _workspace = Completer<WorkspaceData>();

  @override
  Future<WorkspaceData> loadWorkspace() {
    if (!requested.isCompleted) requested.complete();
    return _workspace.future;
  }

  Future<void> complete() async {
    final workspace = await MockStudyAppRepository().loadWorkspace();
    _workspace.complete(workspace);
  }
}
