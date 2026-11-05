import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_session_store.dart';
import '../domain/authentication.dart';

abstract class SessionCredentialStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

class DeviceSessionCredentialStorage implements SessionCredentialStorage {
  DeviceSessionCredentialStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'studyapp.access_session.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

/// Persiste somente sessões ACCESS; challenges continuam apenas em memória.
class SecureAuthSessionStore extends MemoryAuthSessionStore {
  SecureAuthSessionStore({SessionCredentialStorage? storage})
    : _storage = storage ?? DeviceSessionCredentialStorage();

  final SessionCredentialStorage _storage;
  Future<void> _pending = Future<void>.value();

  @override
  Future<void> flush() => _pending;

  @override
  Future<void> restoreSession() async {
    try {
      await _pending;
      final raw = await _storage.read();
      if (raw == null) return;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        clear();
        return;
      }
      final token = json['accessToken'];
      final tokenType = json['tokenType'];
      final expiration = json['expiresAt'];
      final expiresAt = expiration is String
          ? DateTime.tryParse(expiration)
          : null;
      if (token is! String ||
          tokenType != 'Bearer' ||
          expiresAt == null ||
          !expiresAt.isAfter(DateTime.now().toUtc()) ||
          !_isAccessToken(token)) {
        clear();
        return;
      }
      super.startSession(
        AuthenticatedSession(
          accessToken: token,
          tokenType: tokenType,
          expiresAt: expiresAt,
        ),
      );
    } catch (_) {
      // Uma credencial inacessível ou corrompida nunca libera o workspace.
      clear();
    }
  }

  @override
  Future<void> persistSession() {
    final current = session;
    if (current == null ||
        !current.expiresAt.isAfter(DateTime.now().toUtc()) ||
        current.tokenType != 'Bearer' ||
        !_isAccessToken(current.accessToken)) {
      return Future<void>.value();
    }
    final operation = _pending.then(
      (_) => _storage.write(
        jsonEncode({
          'accessToken': current.accessToken,
          'tokenType': current.tokenType,
          'expiresAt': current.expiresAt.toUtc().toIso8601String(),
        }),
      ),
    );
    _pending = operation.catchError((Object _) {});
    return operation;
  }

  @override
  void clear() {
    super.clear();
    final operation = _pending.then((_) => _storage.delete());
    _pending = operation.catchError((Object _) {});
  }

  @override
  void keepChallenge(AuthenticationChallenge challenge) {
    clear();
    super.keepChallenge(challenge);
  }

  bool _isAccessToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic> ||
          payload['token_use'] != 'ACCESS') {
        return false;
      }
      final audience = payload['aud'];
      return audience == 'studyapp-api' ||
          (audience is List<dynamic> && audience.contains('studyapp-api'));
    } catch (_) {
      return false;
    }
  }
}
