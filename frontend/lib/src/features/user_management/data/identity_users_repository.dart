import '../../../core/config/app_config.dart';
import '../../../core/http/identity_api_client.dart';
import '../../studyapp/domain/auth_session_store.dart';
import '../domain/managed_user.dart';
import '../domain/user_management_repository.dart';

class IdentityUsersRepository implements UserManagementRepository {
  IdentityUsersRepository({
    required AppConfig config,
    required this.sessionStore,
    IdentityApiClient? client,
  }) : _client = client ?? IdentityApiClient(config: config);

  final IdentityApiClient _client;
  final AuthSessionStore sessionStore;

  Map<String, String> get _headers {
    final session = sessionStore.session;
    if (session == null) {
      throw StateError('Faça login antes de administrar usuários.');
    }
    return {'authorization': '${session.tokenType} ${session.accessToken}'};
  }

  @override
  Future<List<ManagedUser>> listUsers(
    UserManagementContext context, {
    String? teamId,
  }) async {
    final response = await _client.sendJson(
      'GET',
      'organizations/${context.organizationId.trim()}/users',
      queryParameters: {
        if (teamId != null && teamId.trim().isNotEmpty) 'teamId': teamId.trim(),
      },
      headers: _headers,
    );

    return (response as List<dynamic>)
        .map((json) => ManagedUser.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ManagedUser> createUser(
    UserManagementContext context,
    CreateManagedUserInput input,
  ) async {
    final response = await _client.sendJson(
      'POST',
      'organizations/${context.organizationId.trim()}/users',
      body: input.toJson(),
      headers: _headers,
      expectedStatuses: const {201},
    );

    return ManagedUser.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<ManagedUser> updateUser(
    UserManagementContext context,
    String userId,
    UpdateManagedUserInput input,
  ) async {
    final response = await _client.sendJson(
      'PUT',
      'organizations/${context.organizationId.trim()}/users/${userId.trim()}',
      body: input.toJson(),
      headers: _headers,
    );

    return ManagedUser.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<ManagedUser> changeStatus(
    UserManagementContext context,
    String userId,
    UserStatus status,
  ) async {
    final response = await _client.sendJson(
      'PATCH',
      'organizations/${context.organizationId.trim()}/users/${userId.trim()}/status',
      body: {'status': status.apiValue},
      headers: _headers,
    );

    return ManagedUser.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> disableUser(UserManagementContext context, String userId) async {
    await _client.sendJson(
      'DELETE',
      'organizations/${context.organizationId.trim()}/users/${userId.trim()}',
      headers: _headers,
      expectedStatuses: const {204},
    );
  }

  @override
  Future<ManagedUser> completeInvitation({
    required String token,
    required String password,
    required String passwordConfirmation,
    required bool personalDataConsentAccepted,
  }) async {
    final response = await _client.sendJson(
      'POST',
      'invitations/complete',
      body: {
        'token': token.trim(),
        'password': password,
        'passwordConfirmation': passwordConfirmation,
        'personalDataConsentAccepted': personalDataConsentAccepted,
      },
    );

    return ManagedUser.fromJson(response as Map<String, dynamic>);
  }
}
