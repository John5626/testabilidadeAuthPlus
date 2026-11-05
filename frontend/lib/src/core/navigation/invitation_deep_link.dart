String? invitationTokenFromRoute(String? routeName) {
  if (routeName == null || routeName.isEmpty) return null;
  final uri = Uri.tryParse(routeName);
  if (uri == null) return null;

  final isCustomScheme =
      uri.scheme == 'studyapp' &&
      uri.host == 'invitation' &&
      uri.path == '/complete';
  final isWebPath =
      uri.path == '/invitation/complete' || uri.path == '/complete';
  if (!isCustomScheme && !isWebPath) return null;

  final token = uri.queryParameters['token']?.trim();
  if (token == null || token.isEmpty || token.length > 256) return null;
  return token;
}
