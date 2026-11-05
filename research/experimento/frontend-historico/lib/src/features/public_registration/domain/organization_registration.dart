class RegisterOrganizationAdminInput {
  const RegisterOrganizationAdminInput({
    required this.organizationName,
    required this.organizationDomain,
    required this.teamName,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.passwordConfirmation,
    required this.personalDataConsentAccepted,
  });

  final String organizationName;
  final String organizationDomain;
  final String teamName;
  final String email;
  final String firstName;
  final String? lastName;
  final String password;
  final String passwordConfirmation;
  final bool personalDataConsentAccepted;

  Map<String, Object> toJson() {
    return {
      'organizationName': organizationName.trim(),
      if (organizationDomain.trim().isNotEmpty)
        'organizationDomain': organizationDomain.trim(),
      'teamName': teamName.trim(),
      'email': email.trim(),
      'firstName': firstName.trim(),
      if (lastName?.trim().isNotEmpty ?? false) 'lastName': lastName!.trim(),
      'password': password,
      'passwordConfirmation': passwordConfirmation,
      'personalDataConsentAccepted': personalDataConsentAccepted,
    };
  }
}

class OrganizationAdminRegistration {
  const OrganizationAdminRegistration({
    required this.organizationId,
    required this.organizationName,
    required this.teamId,
    required this.teamName,
    required this.admin,
  });

  factory OrganizationAdminRegistration.fromJson(Map<String, dynamic> json) {
    return OrganizationAdminRegistration(
      organizationId: json['organizationId'] as String,
      organizationName: json['organizationName'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      admin: RegisteredOrganizationAdmin.fromJson(
        json['admin'] as Map<String, dynamic>,
      ),
    );
  }

  final String organizationId;
  final String organizationName;
  final String teamId;
  final String teamName;
  final RegisteredOrganizationAdmin admin;
}

class RegisteredOrganizationAdmin {
  const RegisteredOrganizationAdmin({
    required this.id,
    required this.email,
    required this.displayName,
    required this.status,
    required this.teamRole,
    required this.profiles,
    required this.termsAcceptanceRequired,
  });

  factory RegisteredOrganizationAdmin.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as List<dynamic>? ?? const [];

    return RegisteredOrganizationAdmin(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      status: json['status'] as String,
      teamRole: json['teamRole'] as String,
      profiles: profiles.map((profile) => profile as String).toList(),
      termsAcceptanceRequired: json['termsAcceptanceRequired'] as bool,
    );
  }

  final String id;
  final String email;
  final String displayName;
  final String status;
  final String teamRole;
  final List<String> profiles;
  final bool termsAcceptanceRequired;
}
