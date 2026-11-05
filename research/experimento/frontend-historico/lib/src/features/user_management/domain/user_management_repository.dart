import 'managed_user.dart';

abstract class UserManagementRepository {
  Future<List<ManagedUser>> listUsers(
    UserManagementContext context, {
    String? teamId,
  });

  Future<ManagedUser> createUser(
    UserManagementContext context,
    CreateManagedUserInput input,
  );

  Future<ManagedUser> updateUser(
    UserManagementContext context,
    String userId,
    UpdateManagedUserInput input,
  );

  Future<ManagedUser> changeStatus(
    UserManagementContext context,
    String userId,
    UserStatus status,
  );

  Future<void> disableUser(UserManagementContext context, String userId);

  Future<ManagedUser> completeInvitation({
    required String token,
    required String password,
    required String passwordConfirmation,
    required bool personalDataConsentAccepted,
  });
}
