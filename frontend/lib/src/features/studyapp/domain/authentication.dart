enum AuthChallengeType { termsAcceptanceRequired, mfaRequired }

sealed class AuthenticationResult {
  const AuthenticationResult({required this.expiresAt});

  final DateTime expiresAt;
}

class AuthenticatedSession extends AuthenticationResult {
  const AuthenticatedSession({
    required this.accessToken,
    required this.tokenType,
    required super.expiresAt,
  });

  final String accessToken;
  final String tokenType;
}

class AuthenticationChallenge extends AuthenticationResult {
  const AuthenticationChallenge({
    required this.type,
    required this.challengeToken,
    required super.expiresAt,
    this.tokenType,
  });

  final AuthChallengeType type;
  final String challengeToken;
  final String? tokenType;
}

class RequiredPolicy {
  const RequiredPolicy({
    required this.policyVersionId,
    required this.policyCode,
    required this.title,
    required this.type,
    required this.version,
    required this.content,
    this.contentFormat = 'HTML_SANITIZED',
    required this.contentHash,
    required this.effectiveAt,
    required this.publishedAt,
  });

  final String policyVersionId;
  final String policyCode;
  final String title;
  final String type;
  final String version;
  final String content;
  final String contentFormat;
  final String contentHash;
  final DateTime effectiveAt;
  final DateTime publishedAt;
}

abstract class AuthenticationRepository {
  Future<List<RequiredPolicy>> findCurrentPolicies();

  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  });

  Future<List<RequiredPolicy>> findPendingPolicies({
    required String challengeToken,
  });

  Future<AuthenticationResult> acceptRequiredPolicies({
    required String challengeToken,
    required Set<String> policyVersionIds,
  });

  Future<AuthenticatedSession> verifyMfa({
    required String challengeToken,
    required String code,
  });

  Future<void> requestPasswordRecovery({required String email});

  Future<void> previewPasswordRecovery({required String token});

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  });

  Future<void> changePassword({
    required String accessToken,
    required String tokenType,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
}

class InvalidPasswordRecoveryLinkException implements Exception {
  const InvalidPasswordRecoveryLinkException();

  @override
  String toString() =>
      'Este link não está disponível. Solicite um novo e-mail de recuperação.';
}

class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();

  @override
  String toString() => 'E-mail ou senha inválidos.';
}

class InvalidAuthenticationResponseException implements Exception {
  const InvalidAuthenticationResponseException();

  @override
  String toString() => 'Não foi possível iniciar uma sessão segura.';
}

class AuthenticationChallengeExpiredException implements Exception {
  const AuthenticationChallengeExpiredException();

  @override
  String toString() => 'O desafio expirou. Faça login novamente.';
}

class InvalidMfaCodeException implements Exception {
  const InvalidMfaCodeException();

  @override
  String toString() => 'Código inválido ou expirado. Tente novamente.';
}

class RequiredPoliciesChangedException implements Exception {
  const RequiredPoliciesChangedException();

  @override
  String toString() =>
      'As políticas foram atualizadas. Revise o conteúdo antes de aceitar.';
}
