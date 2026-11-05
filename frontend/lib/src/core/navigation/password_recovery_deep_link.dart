String? passwordRecoveryTokenFromRoute(String? routeName) {
  if (!isPasswordRecoveryRoute(routeName)) return null;
  final uri = Uri.parse(routeName!);
  final token = uri.queryParameters['token']?.trim();
  if (token == null || token.isEmpty || token.length > 256) return null;
  return token;
}

bool isPasswordRecoveryRoute(String? routeName) {
  if (routeName == null || routeName.isEmpty) return false;
  final uri = Uri.tryParse(routeName);
  if (uri == null) return false;

  final isCustomScheme =
      uri.scheme == 'studyapp' &&
      uri.host == 'password-recovery' &&
      uri.path == '/reset';
  final isWebPath = uri.path == '/password-recovery/reset';
  return isCustomScheme || isWebPath;
}
