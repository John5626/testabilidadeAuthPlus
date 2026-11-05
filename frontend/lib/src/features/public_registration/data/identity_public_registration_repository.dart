import '../../../core/config/app_config.dart';
import '../../../core/http/identity_api_client.dart';
import '../domain/organization_registration.dart';
import '../domain/public_registration_repository.dart';

class IdentityPublicRegistrationRepository
    implements PublicRegistrationRepository {
  IdentityPublicRegistrationRepository({
    required AppConfig config,
    IdentityApiClient? client,
  }) : _client = client ?? IdentityApiClient(config: config);

  final IdentityApiClient _client;

  @override
  Future<OrganizationAdminRegistration> registerOrganizationAdmin(
    RegisterOrganizationAdminInput input,
  ) async {
    final response = await _client.sendJson(
      'POST',
      'organizations',
      body: input.toJson(),
      expectedStatuses: const {201},
    );

    return OrganizationAdminRegistration.fromJson(
      response as Map<String, dynamic>,
    );
  }
}
