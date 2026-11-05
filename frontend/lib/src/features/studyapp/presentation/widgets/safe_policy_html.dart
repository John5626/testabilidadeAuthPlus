import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class SafePolicyHtml extends StatelessWidget {
  const SafePolicyHtml({required this.html, super.key});

  final String html;

  @override
  Widget build(BuildContext context) {
    return Html(
      data: html,
      doNotRenderTheseTags: const {
        'script',
        'style',
        'iframe',
        'object',
        'embed',
        'img',
        'video',
        'audio',
      },
      onLinkTap: (url, _, _) => _openSafeLink(url),
    );
  }

  Future<void> _openSafeLink(String? value) async {
    final uri = value == null ? null : Uri.tryParse(value);
    if (uri == null ||
        !const {'http', 'https', 'mailto'}.contains(uri.scheme)) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
