import '../../../core/config/app_config.dart';

class AppStatus {
  const AppStatus({required this.environment, required this.apiBaseUrl});

  final AppEnvironment environment;
  final Uri apiBaseUrl;

  String get environmentLabel => environment.value.toUpperCase();
}
