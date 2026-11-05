import '../../../core/config/app_config.dart';
import '../../../core/http/identity_api_client.dart';
import '../domain/waitlist_repository.dart';

class MarketingWaitlistRepository implements WaitlistRepository {
  MarketingWaitlistRepository({
    required AppConfig config,
    IdentityApiClient? client,
  }) : _client = client ?? IdentityApiClient(config: config);

  final IdentityApiClient _client;

  @override
  Future<void> join(JoinWaitlistInput input) async {
    await _client.sendJson(
      'POST',
      'waitlist',
      module: 'marketing',
      body: input.toJson(),
      expectedStatuses: const {201},
    );
  }
}
