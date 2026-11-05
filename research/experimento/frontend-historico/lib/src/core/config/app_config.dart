enum AppEnvironment {
  dev('dev'),
  hml('hml'),
  prod('prod');

  const AppEnvironment(this.value);

  final String value;

  static AppEnvironment parse(String value) {
    return AppEnvironment.values.firstWhere(
      (environment) => environment.value == value,
      orElse: () => AppEnvironment.dev,
    );
  }
}

class AppConfig {
  AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    Uri? androidStoreUrl,
    this.iosStoreUrl,
  }) : androidStoreUrl = androidStoreUrl ?? Uri.parse(_defaultAndroidStoreUrl);

  factory AppConfig.fromEnvironment() {
    const environmentName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'dev',
    );
    const apiBaseUrlValue = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    );
    const androidStoreUrlValue = String.fromEnvironment(
      'ANDROID_STORE_URL',
      defaultValue: _defaultAndroidStoreUrl,
    );
    const iosStoreUrlValue = String.fromEnvironment(
      'IOS_STORE_URL',
      defaultValue: '',
    );

    return AppConfig(
      environment: AppEnvironment.parse(environmentName),
      apiBaseUrl: Uri.parse(apiBaseUrlValue),
      androidStoreUrl: Uri.parse(androidStoreUrlValue),
      iosStoreUrl: iosStoreUrlValue.trim().isEmpty
          ? null
          : Uri.parse(iosStoreUrlValue.trim()),
    );
  }

  final AppEnvironment environment;
  final Uri apiBaseUrl;
  final Uri androidStoreUrl;
  final Uri? iosStoreUrl;

  bool get isProduction => environment == AppEnvironment.prod;

  static const _defaultAndroidStoreUrl =
      'https://example.invalid/app';
}
