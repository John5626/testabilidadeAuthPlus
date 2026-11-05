import 'package:flutter/foundation.dart';

import '../../features/home/data/app_status_repository.dart';
import '../../features/studyapp/data/identity_studyapp_repository.dart';
import '../../features/studyapp/data/identity_authentication_repository.dart';
import '../../features/studyapp/data/secure_auth_session_store.dart';
import '../../features/studyapp/domain/auth_session_store.dart';
import '../../features/studyapp/domain/authentication.dart';
import '../../features/studyapp/domain/studyapp_repository.dart';
import '../../features/public_registration/data/identity_public_registration_repository.dart';
import '../../features/public_registration/domain/public_registration_repository.dart';
import '../../features/user_management/data/identity_users_repository.dart';
import '../../features/user_management/domain/user_management_repository.dart';
import '../../features/waitlist/data/marketing_waitlist_repository.dart';
import '../../features/waitlist/domain/waitlist_repository.dart';
import '../config/app_config.dart';

class AppDependencies {
  factory AppDependencies({
    required AppConfig config,
    StudyAppRepository? studyAppRepository,
    AuthenticationRepository? authenticationRepository,
  }) {
    final AuthSessionStore sessionStore = kIsWeb
        ? MemoryAuthSessionStore()
        : SecureAuthSessionStore();
    return AppDependencies._(
      config: config,
      appStatusRepository: AppStatusRepository(config: config),
      studyAppRepository:
          studyAppRepository ??
          IdentityStudyAppRepository(
            config: config,
            sessionStore: sessionStore,
          ),
      authenticationRepository:
          authenticationRepository ??
          IdentityAuthenticationRepository(config: config),
      authSessionStore: sessionStore,
      publicRegistrationRepository: IdentityPublicRegistrationRepository(
        config: config,
      ),
      userManagementRepository: IdentityUsersRepository(
        config: config,
        sessionStore: sessionStore,
      ),
      waitlistRepository: MarketingWaitlistRepository(config: config),
    );
  }

  const AppDependencies._({
    required this.config,
    required this.appStatusRepository,
    required this.studyAppRepository,
    required this.authenticationRepository,
    required this.authSessionStore,
    required this.publicRegistrationRepository,
    required this.userManagementRepository,
    required this.waitlistRepository,
  });

  final AppConfig config;
  final AppStatusRepository appStatusRepository;
  final StudyAppRepository studyAppRepository;
  final AuthenticationRepository authenticationRepository;
  final AuthSessionStore authSessionStore;
  final PublicRegistrationRepository publicRegistrationRepository;
  final UserManagementRepository userManagementRepository;
  final WaitlistRepository waitlistRepository;

  Future<void> restoreSession() => authSessionStore.restoreSession();
}
