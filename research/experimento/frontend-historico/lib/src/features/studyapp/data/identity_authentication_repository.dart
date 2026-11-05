import '../../../core/config/app_config.dart';
import '../../../core/http/identity_api_client.dart';
import '../domain/authentication.dart';
import 'auth_login_data_source.dart';

class IdentityAuthenticationRepository implements AuthenticationRepository {
  IdentityAuthenticationRepository({
    required AppConfig config,
    AuthLoginDataSource? dataSource,
  }) : _dataSource =
           dataSource ?? AuthLoginDataSource(IdentityApiClient(config: config));

  final AuthLoginDataSource _dataSource;

  @override
  Future<List<RequiredPolicy>> findCurrentPolicies() {
    return _dataSource.findCurrentPolicies();
  }

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) {
    return _dataSource.signIn(email: email, password: password);
  }

  @override
  Future<List<RequiredPolicy>> findPendingPolicies({
    required String challengeToken,
  }) {
    return _dataSource.findPendingPolicies(challengeToken: challengeToken);
  }

  @override
  Future<AuthenticationResult> acceptRequiredPolicies({
    required String challengeToken,
    required Set<String> policyVersionIds,
  }) {
    return _dataSource.acceptRequiredPolicies(
      challengeToken: challengeToken,
      policyVersionIds: policyVersionIds,
    );
  }

  @override
  Future<AuthenticatedSession> verifyMfa({
    required String challengeToken,
    required String code,
  }) {
    return _dataSource.verifyMfa(challengeToken: challengeToken, code: code);
  }

  @override
  Future<void> requestPasswordRecovery({required String email}) {
    return _dataSource.requestPasswordRecovery(email: email);
  }

  @override
  Future<void> previewPasswordRecovery({required String token}) {
    return _dataSource.previewPasswordRecovery(token: token);
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _dataSource.resetPassword(
      token: token,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  @override
  Future<void> changePassword({
    required String accessToken,
    required String tokenType,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _dataSource.changePassword(
      accessToken: accessToken,
      tokenType: tokenType,
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}
