import 'authentication.dart';

abstract class AuthSessionStore {
  AuthenticatedSession? get session;
  AuthenticationChallenge? get challenge;

  void startSession(AuthenticatedSession session);
  void keepChallenge(AuthenticationChallenge challenge);
  void clearChallenge();
  void clear();

  Future<void> restoreSession();
  Future<void> persistSession();
  Future<void> flush();
}

/// Mantém credenciais somente durante a execução atual do aplicativo.
///
/// Access token e challenges ocupam estados mutuamente exclusivos. Isso impede
/// que um challenge de onboarding ou MFA seja usado como sessão autenticada.
class MemoryAuthSessionStore implements AuthSessionStore {
  AuthenticatedSession? _session;
  AuthenticationChallenge? _challenge;

  @override
  AuthenticatedSession? get session => _session;

  @override
  AuthenticationChallenge? get challenge => _challenge;

  @override
  void startSession(AuthenticatedSession session) {
    _challenge = null;
    _session = session;
  }

  @override
  void keepChallenge(AuthenticationChallenge challenge) {
    _session = null;
    _challenge = challenge;
  }

  @override
  void clearChallenge() {
    _challenge = null;
  }

  @override
  void clear() {
    _session = null;
    _challenge = null;
  }

  @override
  Future<void> restoreSession() async {}

  @override
  Future<void> persistSession() async {}

  @override
  Future<void> flush() async {}
}
