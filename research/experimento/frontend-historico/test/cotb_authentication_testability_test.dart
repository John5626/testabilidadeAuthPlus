import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/studyapp/data/mock_studyapp_repository.dart';
import 'package:frontend/src/features/studyapp/domain/auth_session_store.dart';
import 'package:frontend/src/features/studyapp/domain/authentication.dart';
import 'package:frontend/src/features/studyapp/domain/studyapp_models.dart';
import 'package:frontend/src/features/studyapp/presentation/studyapp_flow_controller.dart';

void main() {
  test('C4 remove sessão expirada sem consultar o workspace', () async {
    final repository = _CountingWorkspaceRepository();
    final sessionStore = MemoryAuthSessionStore()
      ..startSession(
        AuthenticatedSession(
          accessToken: 'expired-access-token',
          tokenType: 'Bearer',
          expiresAt: DateTime.utc(2000),
        ),
      );
    final controller = StudyAppFlowController(
      repository: repository,
      authenticationRepository: _SuccessfulAuthenticationRepository(),
      sessionStore: sessionStore,
    );

    await controller.resumeSession();

    expect(controller.stage, StudyAppStage.login);
    expect(sessionStore.session, isNull);
    expect(repository.workspaceLoads, 0);
  });

  test('C5 falha no workspace não mantém sessão nem libera acesso', () async {
    final sessionStore = MemoryAuthSessionStore();
    final controller = StudyAppFlowController(
      repository: _FailingWorkspaceRepository(),
      authenticationRepository: _SuccessfulAuthenticationRepository(),
      sessionStore: sessionStore,
    );

    final success = await controller.signIn(
      email: 'fixture-b3cc0475bb@example.invalid',
      password: 'synthetic-password',
    );

    expect(success, isFalse);
    expect(controller.stage, StudyAppStage.login);
    expect(controller.workspace, isNull);
    expect(sessionStore.session, isNull);
  });
}

final _session = AuthenticatedSession(
  accessToken: 'synthetic-access-token',
  tokenType: 'Bearer',
  expiresAt: DateTime.utc(2099),
);

class _CountingWorkspaceRepository extends MockStudyAppRepository {
  int workspaceLoads = 0;

  @override
  Future<WorkspaceData> loadWorkspace() {
    workspaceLoads += 1;
    return super.loadWorkspace();
  }
}

class _FailingWorkspaceRepository extends MockStudyAppRepository {
  @override
  Future<WorkspaceData> loadWorkspace() async {
    throw StateError('synthetic workspace failure');
  }
}

class _SuccessfulAuthenticationRepository implements AuthenticationRepository {
  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) async => _session;

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
