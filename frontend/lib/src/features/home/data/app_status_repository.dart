import '../../../core/config/app_config.dart';
import '../domain/app_status.dart';

class AppStatusRepository {
  const AppStatusRepository({required this.config});

  final AppConfig config;

  Future<AppStatus> load() async {
    return AppStatus(
      environment: config.environment,
      apiBaseUrl: config.apiBaseUrl,
    );
  }
}
