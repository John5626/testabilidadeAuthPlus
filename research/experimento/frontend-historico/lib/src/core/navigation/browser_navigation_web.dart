import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:web/web.dart' as web;

import 'platform_store_destination.dart';

void configureBrowserNavigation() => usePathUrlStrategy();

void clearInvitationTokenFromBrowserUrl() {
  web.window.history.replaceState(null, '', '/invitation/complete');
}

void clearPasswordRecoveryTokenFromBrowserUrl() {
  web.window.history.replaceState(null, '', '/password-recovery/reset');
}

Future<bool> openPlatformStore({
  required Uri androidStoreUrl,
  required Uri? iosStoreUrl,
}) async {
  final target = platformStoreDestination(
    userAgent: web.window.navigator.userAgent,
    androidStoreUrl: androidStoreUrl,
    iosStoreUrl: iosStoreUrl,
  );
  if (target == null || !target.hasScheme) return false;
  web.window.location.assign(target.toString());
  return true;
}
