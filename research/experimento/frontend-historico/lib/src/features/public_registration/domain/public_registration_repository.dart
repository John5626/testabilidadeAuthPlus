import 'organization_registration.dart';

abstract class PublicRegistrationRepository {
  Future<OrganizationAdminRegistration> registerOrganizationAdmin(
    RegisterOrganizationAdminInput input,
  );
}
