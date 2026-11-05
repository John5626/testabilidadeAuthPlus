import 'package:flutter/foundation.dart';

import '../../../core/http/identity_api_client.dart';

import '../domain/auth_session_store.dart';
import '../domain/authentication.dart';
import '../domain/studyapp_models.dart';
import '../domain/studyapp_repository.dart';
import '../../public_registration/domain/organization_registration.dart';
import '../../public_registration/domain/public_registration_repository.dart';

enum StudyAppStage {
  restoring,
  landing,
  registration,
  invitation,
  passwordReset,
  firstAccess,
  login,
  policyOnboarding,
  mfaChallenge,
  workspace,
}

class StudyAppFlowController extends ChangeNotifier {
  StudyAppFlowController({
    required this.repository,
    this.publicRegistrationRepository,
    required this.authenticationRepository,
    required this.sessionStore,
  });

  final StudyAppRepository repository;
  final PublicRegistrationRepository? publicRegistrationRepository;
  final AuthenticationRepository authenticationRepository;
  final AuthSessionStore sessionStore;

  StudyAppStage _stage = StudyAppStage.landing;
  WorkspaceData? _workspace;
  TeamInvitationPreview? _invitationPreview;
  TeamInvitationAcceptance? _invitationAcceptance;
  String? _invitationToken;
  String? _passwordRecoveryToken;
  bool _passwordRecoveryLinkVerified = false;
  bool _passwordRecoveryLinkInvalid = false;
  bool _passwordResetCompleted = false;
  int _passwordRecoveryGeneration = 0;
  int _authenticationGeneration = 0;
  int? _activeAuthenticationGeneration;
  List<RequiredPolicy> _pendingPolicies = const [];
  bool _busy = false;
  String? _errorMessage;
  String? _noticeMessage;

  StudyAppStage get stage => _stage;
  WorkspaceData? get workspace => _workspace;
  TeamInvitationPreview? get invitationPreview => _invitationPreview;
  TeamInvitationAcceptance? get invitationAcceptance => _invitationAcceptance;
  String? get invitationToken => _invitationToken;
  bool get passwordRecoveryLinkVerified => _passwordRecoveryLinkVerified;
  bool get passwordRecoveryLinkInvalid => _passwordRecoveryLinkInvalid;
  bool get passwordResetCompleted => _passwordResetCompleted;
  List<RequiredPolicy> get pendingPolicies => _pendingPolicies;
  bool get isBusy => _busy;
  String? get errorMessage => _errorMessage;
  String? get noticeMessage => _noticeMessage;

  Future<List<RequiredPolicy>> findCurrentPolicies() =>
      authenticationRepository.findCurrentPolicies();

  Future<void> resumeSession() async {
    final session = sessionStore.session;
    if (session == null) return;
    if (!session.expiresAt.isAfter(DateTime.now().toUtc())) {
      sessionStore.clear();
      _setStage(StudyAppStage.login);
      return;
    }
    _stage = StudyAppStage.restoring;
    _errorMessage = null;
    notifyListeners();
    try {
      final workspace = await repository.loadWorkspace();
      if (_stage != StudyAppStage.restoring) return;
      _workspace = workspace;
      _stage = StudyAppStage.workspace;
    } on IdentitySessionInvalidException {
      if (_stage != StudyAppStage.restoring) return;
      sessionStore.clear();
      _stage = StudyAppStage.login;
    } catch (_) {
      if (_stage != StudyAppStage.restoring) return;
      if (sessionStore.session == null) {
        _stage = StudyAppStage.login;
      } else {
        _errorMessage = 'Não foi possível confirmar a sessão. Tente novamente.';
      }
    } finally {
      notifyListeners();
    }
  }

  void openLanding() {
    sessionStore.clear();
    _workspace = null;
    _pendingPolicies = const [];
    _discardInvitation();
    _setStage(StudyAppStage.landing);
  }

  Future<void> logout() async {
    sessionStore.clear();
    await sessionStore.flush();
    _workspace = null;
    _pendingPolicies = const [];
    _discardInvitation();
    _setStage(StudyAppStage.landing);
  }

  void openRegistration() => _setStage(StudyAppStage.registration);
  void openLogin() {
    sessionStore.clear();
    _pendingPolicies = const [];
    _discardInvitation();
    _setStage(StudyAppStage.login);
  }

  void returnToLoginAfterSessionInvalidation() {
    sessionStore.clear();
    _workspace = null;
    _pendingPolicies = const [];
    _discardInvitation();
    _discardPasswordRecovery();
    _noticeMessage = 'Sua sessão não está mais disponível. Entre novamente.';
    _stage = StudyAppStage.login;
    _errorMessage = null;
    notifyListeners();
  }

  void leaveAuthenticationChallenge() {
    sessionStore.clear();
    _pendingPolicies = const [];
    _setStage(StudyAppStage.login);
  }

  void openInvitation() {
    sessionStore.clear();
    _discardInvitation();
    _setStage(StudyAppStage.invitation);
  }

  void openInvitationFromLink(String token) {
    sessionStore.clear();
    _invitationPreview = null;
    _invitationAcceptance = null;
    _invitationToken = token;
    _setStage(StudyAppStage.invitation);
  }

  void _discardInvitation() {
    _invitationPreview = null;
    _invitationAcceptance = null;
    _invitationToken = null;
  }

  Future<void> openPasswordRecoveryFromLink(String token) async {
    sessionStore.clear();
    _workspace = null;
    _discardInvitation();
    _passwordRecoveryGeneration += 1;
    _passwordRecoveryToken = token;
    _passwordRecoveryLinkVerified = false;
    _passwordRecoveryLinkInvalid = false;
    _passwordResetCompleted = false;
    _setStage(StudyAppStage.passwordReset);
    await retryPasswordRecoveryPreview(force: true);
  }

  void openInvalidPasswordRecoveryLink() {
    sessionStore.clear();
    _workspace = null;
    _discardInvitation();
    _discardPasswordRecovery();
    _passwordRecoveryLinkInvalid = true;
    _setStage(StudyAppStage.passwordReset);
  }

  Future<void> retryPasswordRecoveryPreview({bool force = false}) async {
    final token = _passwordRecoveryToken;
    if ((_busy && !force) || token == null) return;
    final generation = _passwordRecoveryGeneration;
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await authenticationRepository.previewPasswordRecovery(token: token);
      if (generation != _passwordRecoveryGeneration) return;
      _passwordRecoveryLinkVerified = true;
    } on InvalidPasswordRecoveryLinkException {
      if (generation != _passwordRecoveryGeneration) return;
      _passwordRecoveryLinkInvalid = true;
      _passwordRecoveryToken = null;
    } catch (_) {
      if (generation != _passwordRecoveryGeneration) return;
      _errorMessage = 'Não foi possível verificar o link. Tente novamente.';
    } finally {
      if (generation == _passwordRecoveryGeneration) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  Future<bool> resetPasswordFromLink({
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = _passwordRecoveryToken;
    if (_busy || !_passwordRecoveryLinkVerified || token == null) return false;
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await authenticationRepository.resetPassword(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      _discardPasswordRecovery();
      _passwordResetCompleted = true;
      _noticeMessage = 'Senha redefinida. Entre com a nova credencial.';
      return true;
    } catch (_) {
      _errorMessage =
          'Não foi possível redefinir a senha. O link pode estar indisponível ou a senha não foi aceita.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _discardPasswordRecovery() {
    _passwordRecoveryGeneration += 1;
    _passwordRecoveryToken = null;
    _passwordRecoveryLinkVerified = false;
    _passwordRecoveryLinkInvalid = false;
    _passwordResetCompleted = false;
  }

  Future<bool> validateInvitation(String token) async {
    _busy = true;
    _errorMessage = null;
    _invitationPreview = null;
    notifyListeners();
    try {
      _invitationPreview = await repository.validateTeamInvitation(token);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> acceptInvitation(AcceptTeamInvitationInput input) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final acceptance = await repository.acceptTeamInvitation(input);
      _invitationAcceptance = acceptance;
      _invitationPreview = null;
      _invitationToken = null;
      final session = acceptance.session;
      if (session != null) {
        await _startAuthenticatedSession(session);
      }
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> register(RegistrationDraft draft) async {
    final registrationRepository = publicRegistrationRepository;
    if (registrationRepository == null) {
      _errorMessage = 'Cadastro indisponível neste ambiente.';
      notifyListeners();
      return false;
    }
    final success = await _run(() async {
      await registrationRepository.registerOrganizationAdmin(
        RegisterOrganizationAdminInput(
          organizationName: draft.organizationName,
          organizationDomain: draft.organizationDomain,
          teamName: draft.teamName,
          email: draft.email,
          firstName: draft.firstName,
          lastName: draft.lastName,
          password: draft.password,
          passwordConfirmation: draft.passwordConfirmation,
          personalDataConsentAccepted: draft.personalDataConsentAccepted,
        ),
      );
    });
    if (success) {
      _noticeMessage =
          'Cadastro realizado. Entre com suas credenciais para aceitar as políticas vigentes.';
      _stage = StudyAppStage.login;
      notifyListeners();
    }
    return success;
  }

  Future<bool> completeFirstAccess(FirstAccessSetup setup) async {
    final success = await _run(() => repository.completeFirstAccess(setup));
    if (success) {
      await _loadWorkspace();
    }
    return success;
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (_busy) return false;

    final generation = ++_authenticationGeneration;
    _activeAuthenticationGeneration = generation;
    _busy = true;
    _errorMessage = null;
    _noticeMessage = null;
    sessionStore.clear();
    _pendingPolicies = const [];
    notifyListeners();
    try {
      final result = await authenticationRepository.signIn(
        email: email,
        password: password,
      );
      if (!_isAuthenticationCurrent(generation)) return false;
      switch (result) {
        case AuthenticatedSession():
          await _startAuthenticatedSession(
            result,
            authenticationGeneration: generation,
          );
        case AuthenticationChallenge(
          type: AuthChallengeType.termsAcceptanceRequired,
        ):
          sessionStore.keepChallenge(result);
          _workspace = null;
          _stage = StudyAppStage.policyOnboarding;
          try {
            final policies = await authenticationRepository.findPendingPolicies(
              challengeToken: result.challengeToken,
            );
            if (!_isAuthenticationCurrent(generation)) return false;
            _pendingPolicies = policies;
          } on AuthenticationChallengeExpiredException {
            if (!_isAuthenticationCurrent(generation)) return false;
            sessionStore.clear();
            _stage = StudyAppStage.login;
            rethrow;
          } catch (error) {
            if (!_isAuthenticationCurrent(generation)) return false;
            _errorMessage = error.toString();
          }
        case AuthenticationChallenge(type: AuthChallengeType.mfaRequired):
          sessionStore.keepChallenge(result);
          _workspace = null;
          _stage = StudyAppStage.mfaChallenge;
      }
      return _isAuthenticationCurrent(generation);
    } catch (error) {
      if (!_isAuthenticationCurrent(generation)) return false;
      sessionStore.clear();
      _errorMessage = error.toString();
      return false;
    } finally {
      if (_activeAuthenticationGeneration == generation) {
        _activeAuthenticationGeneration = null;
        _busy = false;
        notifyListeners();
      }
    }
  }

  Future<bool> retryPolicyOnboarding() async {
    if (_busy) return false;
    final challenge = sessionStore.challenge;
    if (challenge?.type != AuthChallengeType.termsAcceptanceRequired) {
      return false;
    }

    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _ensureChallengeIsUsable(challenge!);
      _pendingPolicies = await authenticationRepository.findPendingPolicies(
        challengeToken: challenge.challengeToken,
      );
      return true;
    } on AuthenticationChallengeExpiredException catch (error) {
      _returnToLoginAfterChallengeFailure(error);
      return false;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> acceptRequiredPolicies() async {
    if (_busy || _pendingPolicies.isEmpty) return false;
    final challenge = sessionStore.challenge;
    if (challenge?.type != AuthChallengeType.termsAcceptanceRequired) {
      return false;
    }

    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _ensureChallengeIsUsable(challenge!);
      final result = await authenticationRepository.acceptRequiredPolicies(
        challengeToken: challenge.challengeToken,
        policyVersionIds: _pendingPolicies
            .map((policy) => policy.policyVersionId)
            .toSet(),
      );
      _pendingPolicies = const [];
      switch (result) {
        case AuthenticatedSession():
          await _startAuthenticatedSession(result);
        case AuthenticationChallenge(type: AuthChallengeType.mfaRequired):
          sessionStore.keepChallenge(result);
          _workspace = null;
          _stage = StudyAppStage.mfaChallenge;
        case AuthenticationChallenge():
          throw const InvalidAuthenticationResponseException();
      }
      return true;
    } on RequiredPoliciesChangedException catch (error) {
      _errorMessage = error.toString();
      try {
        _pendingPolicies = await authenticationRepository.findPendingPolicies(
          challengeToken: challenge!.challengeToken,
        );
      } on AuthenticationChallengeExpiredException catch (expired) {
        _returnToLoginAfterChallengeFailure(expired);
      } catch (_) {
        // Mantém a mensagem segura de atualização e permite nova tentativa.
      }
      return false;
    } on AuthenticationChallengeExpiredException catch (error) {
      _returnToLoginAfterChallengeFailure(error);
      return false;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> verifyMfa(String code) async {
    if (_busy) return false;
    final challenge = sessionStore.challenge;
    if (challenge?.type != AuthChallengeType.mfaRequired) return false;

    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _ensureChallengeIsUsable(challenge!);
      final session = await authenticationRepository.verifyMfa(
        challengeToken: challenge.challengeToken,
        code: code,
      );
      await _startAuthenticatedSession(session);
      return true;
    } on AuthenticationChallengeExpiredException catch (error) {
      _returnToLoginAfterChallengeFailure(error);
      return false;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> requestPasswordRecovery(String email) async {
    return _run(
      () => authenticationRepository.requestPasswordRecovery(email: email),
    );
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final success = await _run(
      () => authenticationRepository.resetPassword(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
    );
    if (success) {
      _noticeMessage = 'Senha redefinida. Entre com a nova credencial.';
      notifyListeners();
    }
    return success;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final session = sessionStore.session;
    if (session == null) return false;
    final success = await _run(() async {
      try {
        await authenticationRepository.changePassword(
          accessToken: session.accessToken,
          tokenType: session.tokenType,
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        );
      } on IdentityApiException catch (error) {
        if (error.statusCode == 401 || error.statusCode == 403) {
          await repository.loadWorkspace();
        }
        rethrow;
      }
    });
    if (!success && sessionStore.session == null) {
      returnToLoginAfterSessionInvalidation();
      return false;
    }
    if (success) {
      sessionStore.clear();
      _workspace = null;
      _noticeMessage = 'Senha alterada. Entre novamente para continuar.';
      _stage = StudyAppStage.login;
      notifyListeners();
    }
    return success;
  }

  Future<void> enterDemo() => _loadWorkspace();

  Future<void> refreshWorkspace() async {
    _workspace = await repository.loadWorkspace();
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _startAuthenticatedSession(
    AuthenticatedSession session, {
    int? authenticationGeneration,
  }) async {
    if (authenticationGeneration != null &&
        !_isAuthenticationCurrent(authenticationGeneration)) {
      return;
    }
    sessionStore.startSession(session);
    try {
      final workspace = await repository.loadWorkspace();
      if (authenticationGeneration != null &&
          !_isAuthenticationCurrent(authenticationGeneration)) {
        sessionStore.clear();
        return;
      }
      _workspace = workspace;
      _stage = StudyAppStage.workspace;
      await sessionStore.persistSession();
    } catch (_) {
      if (authenticationGeneration != null &&
          !_isAuthenticationCurrent(authenticationGeneration)) {
        return;
      }
      sessionStore.clear();
      _workspace = null;
      _stage = StudyAppStage.login;
      rethrow;
    }
  }

  bool _isAuthenticationCurrent(int generation) =>
      generation == _authenticationGeneration &&
      _activeAuthenticationGeneration == generation;

  void _invalidateAuthenticationOperation() {
    _authenticationGeneration += 1;
    if (_activeAuthenticationGeneration != null) {
      _activeAuthenticationGeneration = null;
      _busy = false;
    }
  }

  void _ensureChallengeIsUsable(AuthenticationChallenge challenge) {
    if (!challenge.expiresAt.isAfter(DateTime.now().toUtc())) {
      throw const AuthenticationChallengeExpiredException();
    }
  }

  void _returnToLoginAfterChallengeFailure(Object error) {
    sessionStore.clear();
    _pendingPolicies = const [];
    _stage = StudyAppStage.login;
    _errorMessage = error.toString();
  }

  Future<void> _loadWorkspace() async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _workspace = await repository.loadWorkspace();
      _stage = StudyAppStage.workspace;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _setStage(StudyAppStage value) {
    _invalidateAuthenticationOperation();
    if (value != StudyAppStage.passwordReset) _discardPasswordRecovery();
    _stage = value;
    _errorMessage = null;
    if (value != StudyAppStage.login) {
      _noticeMessage = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _discardPasswordRecovery();
    super.dispose();
  }
}
