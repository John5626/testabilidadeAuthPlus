import 'dart:async';

import 'package:flutter/services.dart';

typedef ClipboardReadText = Future<String?> Function();
typedef ClipboardWriteText = Future<void> Function(String value);

Future<void> copySensitiveTextTemporarily(
  String value, {
  Duration lifetime = const Duration(seconds: 60),
  ClipboardReadText? readText,
  ClipboardWriteText? writeText,
}) async {
  final reader =
      readText ?? () async => (await Clipboard.getData('text/plain'))?.text;
  final writer =
      writeText ??
      (String text) => Clipboard.setData(ClipboardData(text: text));

  await writer(value);
  unawaited(
    Future<void>.delayed(lifetime, () async {
      try {
        if (await reader() == value) await writer('');
      } catch (_) {
        // A limpeza é melhor esforço em plataformas sem leitura de clipboard.
      }
    }),
  );
}
