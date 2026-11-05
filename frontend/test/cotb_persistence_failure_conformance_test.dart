import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/studyapp/data/mock_studyapp_repository.dart';
import 'package:frontend/src/features/studyapp/domain/auth_session_store.dart';
import 'package:frontend/src/features/studyapp/domain/authentication.dart';
import 'package:frontend/src/features/studyapp/presentation/studyapp_flow_controller.dart';

void main() {
  test(
    'falha ao persistir sessão não libera estado autenticado parcial',
    () async {
      final sessionStore = _FailingPersistenceSessionStore();
      final controller = StudyAppFlowController(
        repository: MockStudyAppRepository(),
        authenticationRepository: _SuccessfulAuthenticationRepository(),
        sessionStore: sessionStore,
      );

      controller.openLogin();
      final success = await controller.signIn(
        email: 'fixture-b3cc0475bb@example.invalid',
        password: 'synthetic-password',
      );

      expect(success, isFalse);
      expect(
        [controller.stage, controller.workspace, sessionStore.session],
        [StudyAppStage.login, null, null],
        reason:
            'falha de persistência deve reverter estágio, workspace e sessão',
      );
      expect(
        controller.errorMessage,
        contains('synthetic persistence failure'),
      );
    },
  );
}

final _session = AuthenticatedSession(
  accessToken: 'synthetic-access-token',
  tokenType: 'Bearer',
  expiresAt: DateTime.utc(2099),
);

class _FailingPersistenceSessionStore extends MemoryAuthSessionStore {
  @override
  Future<void> persistSession() async {
    throw StateError('synthetic persistence failure');
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
