Uri? platformStoreDestination({
  required String userAgent,
  required Uri androidStoreUrl,
  required Uri? iosStoreUrl,
}) {
  final agent = userAgent.toLowerCase();
  final isIos =
      agent.contains('iphone') ||
      agent.contains('ipad') ||
      agent.contains('ipod');
  return isIos ? iosStoreUrl : androidStoreUrl;
}
