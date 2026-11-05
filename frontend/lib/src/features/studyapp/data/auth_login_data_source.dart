import 'dart:convert';

import '../../../core/http/identity_api_client.dart';
import '../domain/authentication.dart';

class AuthLoginDataSource {
  AuthLoginDataSource(this._client);

  final IdentityApiClient _client;

  Future<List<RequiredPolicy>> findCurrentPolicies() async {
    final response = await _client.sendJson('GET', 'public/policies');
    return _policiesFromResponse(response);
  }

  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.sendJson(
        'POST',
        'login',
        module: 'auth',
        body: {'email': email.trim(), 'password': password},
      );

      return _authenticatedSession(_jsonObject(response));
    } on IdentityApiException catch (error) {
      if (error.statusCode == 401) {
        throw const InvalidCredentialsException();
      }
      if (error.statusCode == 403 && error.responseBody != null) {
        return _challenge(error.responseBody!);
      }
      rethrow;
    }
  }

  Future<List<RequiredPolicy>> findPendingPolicies({
    required String challengeToken,
  }) async {
    try {
      final response = await _client.sendJson(
        'GET',
        'onboarding/policies',
        headers: {'authorization': 'Bearer $challengeToken'},
      );
      return _policiesFromResponse(response);
    } on IdentityApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        throw const AuthenticationChallengeExpiredException();
      }
      rethrow;
    }
  }

  Future<AuthenticationResult> acceptRequiredPolicies({
    required String challengeToken,
    required Set<String> policyVersionIds,
  }) async {
    if (policyVersionIds.isEmpty) {
      throw const InvalidAuthenticationResponseException();
    }
    try {
      final response = await _client.sendJson(
        'POST',
        'onboarding/policy-acceptances',
        headers: {'authorization': 'Bearer $challengeToken'},
        body: {
          'policyVersionIds': policyVersionIds.toList(growable: false),
          'accepted': true,
        },
        expectedStatuses: const {200},
      );
      return _authenticatedSession(_jsonObject(response));
    } on IdentityApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        throw const AuthenticationChallengeExpiredException();
      }
      if (error.statusCode == 409) {
        throw const RequiredPoliciesChangedException();
      }
      rethrow;
    }
  }

  Future<AuthenticatedSession> verifyMfa({
    required String challengeToken,
    required String code,
  }) async {
    try {
      final response = await _client.sendJson(
        'POST',
        'mfa/verify',
        module: 'auth',
        body: {'challengeToken': challengeToken, 'code': code},
      );
      return _authenticatedSession(_jsonObject(response));
    } on IdentityApiException catch (error) {
      if (error.statusCode == 401) {
        throw const InvalidMfaCodeException();
      }
      rethrow;
    }
  }

  Future<void> requestPasswordRecovery({required String email}) async {
    await _client.sendJson(
      'POST',
      'password-recovery',
      module: 'auth',
      body: {'email': email.trim()},
      expectedStatuses: const {202},
    );
  }

  Future<void> previewPasswordRecovery({required String token}) async {
    try {
      await _client.sendJson(
        'POST',
        'password-recovery/preview',
        module: 'auth',
        body: {'token': token.trim()},
        expectedStatuses: const {204},
      );
    } on IdentityApiException catch (error) {
      if (error.statusCode == 400) {
        throw const InvalidPasswordRecoveryLinkException();
      }
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.sendJson(
      'POST',
      'password-recovery/reset',
      module: 'auth',
      body: {
        'token': token.trim(),
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      expectedStatuses: const {204},
    );
  }

  Future<void> changePassword({
    required String accessToken,
    required String tokenType,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.sendJson(
      'POST',
      'password/change',
      module: 'auth',
      headers: {'authorization': '$tokenType $accessToken'},
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      expectedStatuses: const {204},
    );
  }

  AuthenticatedSession _authenticatedSession(Map<String, dynamic> json) {
    final accessToken = _requiredString(json, 'accessToken');
    final tokenType = _requiredString(json, 'tokenType');
    final expiresAt = _requiredDateTime(json, 'expiresAt');

    if (tokenType.toLowerCase() != 'bearer' ||
        !_hasJwtPurpose(
          accessToken,
          tokenUse: 'ACCESS',
          audience: 'studyapp-api',
        )) {
      throw const InvalidAuthenticationResponseException();
    }

    return AuthenticatedSession(
      accessToken: accessToken,
      tokenType: tokenType,
      expiresAt: expiresAt,
    );
  }

  AuthenticationChallenge _challenge(Map<String, dynamic> json) {
    final rawType = _requiredString(json, 'challengeType');
    final challengeToken = _requiredString(json, 'challengeToken');
    final expiresAt = _requiredDateTime(json, 'expiresAt');

    switch (rawType) {
      case 'TERMS_ACCEPTANCE_REQUIRED':
        final tokenType = _requiredString(json, 'tokenType');
        if (tokenType.toLowerCase() != 'bearer' ||
            !_hasJwtPurpose(
              challengeToken,
              tokenUse: 'ONBOARDING',
              audience: 'studyapp-onboarding',
            )) {
          throw const InvalidAuthenticationResponseException();
        }
        return AuthenticationChallenge(
          type: AuthChallengeType.termsAcceptanceRequired,
          challengeToken: challengeToken,
          tokenType: tokenType,
          expiresAt: expiresAt,
        );
      case 'MFA_REQUIRED':
        return AuthenticationChallenge(
          type: AuthChallengeType.mfaRequired,
          challengeToken: challengeToken,
          expiresAt: expiresAt,
        );
      default:
        throw const InvalidAuthenticationResponseException();
    }
  }

  RequiredPolicy _requiredPolicy(Map<String, dynamic> json) {
    return RequiredPolicy(
      policyVersionId: _requiredString(json, 'policyVersionId'),
      policyCode: _requiredString(json, 'policyCode'),
      title: _requiredString(json, 'title'),
      type: _requiredString(json, 'type'),
      version: _requiredString(json, 'version'),
      content: _requiredString(json, 'content'),
      contentFormat: json['contentFormat'] as String? ?? 'HTML_SANITIZED',
      contentHash: _requiredString(json, 'contentHash'),
      effectiveAt: _requiredDateTime(json, 'effectiveAt'),
      publishedAt: _requiredDateTime(json, 'publishedAt'),
    );
  }

  List<RequiredPolicy> _policiesFromResponse(Object? response) {
    if (response is! List<dynamic>) {
      throw const InvalidAuthenticationResponseException();
    }
    final policies = response
        .map((item) => _requiredPolicy(_jsonObject(item)))
        .toList(growable: false);
    if (policies.isEmpty) {
      throw const InvalidAuthenticationResponseException();
    }
    return policies;
  }

  Map<String, dynamic> _jsonObject(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const InvalidAuthenticationResponseException();
  }

  String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw const InvalidAuthenticationResponseException();
  }

  DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw const InvalidAuthenticationResponseException();
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw const InvalidAuthenticationResponseException();
    }
    return parsed;
  }

  bool _hasJwtPurpose(
    String token, {
    required String tokenUse,
    required String audience,
  }) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic> ||
          payload['token_use'] != tokenUse) {
        return false;
      }

      final claim = payload['aud'];
      return claim == audience ||
          (claim is List<dynamic> && claim.contains(audience));
    } on FormatException {
      return false;
    }
  }
}
