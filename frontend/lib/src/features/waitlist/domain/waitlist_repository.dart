enum WaitlistUsageProfile {
  personal('Uso pessoal', 'PERSONAL'),
  smallTeam('Equipe pequena', 'SMALL_TEAM'),
  company('Empresa', 'COMPANY'),
  other('Outro', 'OTHER');

  const WaitlistUsageProfile(this.label, this.apiValue);

  final String label;
  final String apiValue;
}

class JoinWaitlistInput {
  const JoinWaitlistInput({
    required this.name,
    required this.email,
    required this.usageProfile,
    required this.receiveLaunchNews,
  });

  final String? name;
  final String email;
  final WaitlistUsageProfile? usageProfile;
  final bool receiveLaunchNews;

  Map<String, Object?> toJson() => {
    if (name?.isNotEmpty ?? false) 'name': name,
    'email': email,
    if (usageProfile != null) 'usageProfile': usageProfile!.apiValue,
    'receiveLaunchNews': receiveLaunchNews,
  };
}

abstract interface class WaitlistRepository {
  Future<void> join(JoinWaitlistInput input);
}
