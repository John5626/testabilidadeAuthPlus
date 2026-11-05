import 'package:flutter/material.dart';

import 'authentication_challenge_view.dart';
import 'studyapp_flow_controller.dart';
import 'accept_team_invitation_view.dart';
import 'first_access_view.dart';
import 'landing_view.dart';
import 'login_view.dart';
import 'password_reset_view.dart';
import 'registration_flow_view.dart';
import 'workspace/workspace_view.dart';

class StudyAppRootView extends StatelessWidget {
  const StudyAppRootView({
    required this.controller,
    this.webInvitationFlow = false,
    this.onInvitationAccepted,
    super.key,
  });

  final StudyAppFlowController controller;
  final bool webInvitationFlow;
  final Future<void> Function()? onInvitationAccepted;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: switch (controller.stage) {
            StudyAppStage.restoring => Scaffold(
              key: const ValueKey('restoring'),
              body: Center(
                child: controller.errorMessage == null
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: controller.resumeSession,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            StudyAppStage.landing => LandingView(
              key: const ValueKey('landing'),
              onCreateAccount: controller.openRegistration,
              onLogin: controller.openLogin,
              onAcceptInvitation: controller.openInvitation,
              onExploreDemo: controller.enterDemo,
            ),
            StudyAppStage.registration => RegistrationFlowView(
              key: const ValueKey('registration'),
              isBusy: controller.isBusy,
              errorMessage: controller.errorMessage,
              onOpenPolicies: controller.findCurrentPolicies,
              onBack: controller.openLanding,
              onSubmit: controller.register,
            ),
            StudyAppStage.firstAccess => FirstAccessView(
              key: const ValueKey('first-access'),
              isBusy: controller.isBusy,
              errorMessage: controller.errorMessage,
              onComplete: controller.completeFirstAccess,
            ),
            StudyAppStage.login => LoginView(
              key: const ValueKey('login'),
              controller: controller,
              isBusy: controller.isBusy,
              errorMessage: controller.errorMessage,
              noticeMessage: controller.noticeMessage,
              onBack: controller.openLanding,
              onCreateAccount: controller.openRegistration,
              onAcceptInvitation: controller.openInvitation,
              onLogin: (email, password) =>
                  controller.signIn(email: email, password: password),
              onRequestPasswordRecovery: controller.requestPasswordRecovery,
            ),
            StudyAppStage.passwordReset => PasswordResetView(
              key: const ValueKey('password-reset'),
              isBusy: controller.isBusy,
              linkVerified: controller.passwordRecoveryLinkVerified,
              linkInvalid: controller.passwordRecoveryLinkInvalid,
              completed: controller.passwordResetCompleted,
              errorMessage: controller.errorMessage,
              onRetryPreview: () => controller.retryPasswordRecoveryPreview(),
              onReset: (password, confirmation) =>
                  controller.resetPasswordFromLink(
                    newPassword: password,
                    confirmPassword: confirmation,
                  ),
              onLogin: controller.openLogin,
            ),
            StudyAppStage.policyOnboarding => PolicyOnboardingView(
              key: const ValueKey('policy-onboarding'),
              policies: controller.pendingPolicies,
              isBusy: controller.isBusy,
              errorMessage: controller.errorMessage,
              onRetry: controller.retryPolicyOnboarding,
              onAccept: controller.acceptRequiredPolicies,
              onCancel: controller.leaveAuthenticationChallenge,
            ),
            StudyAppStage.mfaChallenge => MfaChallengeView(
              key: const ValueKey('mfa-challenge'),
              isBusy: controller.isBusy,
              errorMessage: controller.errorMessage,
              onVerify: controller.verifyMfa,
              onCancel: controller.leaveAuthenticationChallenge,
            ),
            StudyAppStage.invitation => AcceptTeamInvitationView(
              key: const ValueKey('accept-invitation'),
              isBusy: controller.isBusy,
              errorMessage: controller.errorMessage,
              preview: controller.invitationPreview,
              acceptance: controller.invitationAcceptance,
              initialToken: controller.invitationToken,
              onBack: controller.openLanding,
              onValidate: controller.validateInvitation,
              onAccept: controller.acceptInvitation,
              onGoToLogin: controller.openLogin,
              webInvitationFlow: webInvitationFlow,
              onInvitationAccepted: onInvitationAccepted,
            ),
            StudyAppStage.workspace => WorkspaceView(
              key: const ValueKey('workspace'),
              data: controller.workspace!,
              repository: controller.repository,
              onChangePassword: controller.changePassword,
              onLogout: controller.logout,
              onSessionInvalidated:
                  controller.returnToLoginAfterSessionInvalidation,
            ),
          },
        );
      },
    );
  }
}
