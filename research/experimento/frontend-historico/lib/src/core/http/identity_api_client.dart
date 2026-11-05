import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class IdentityApiClient {
  IdentityApiClient({required this.config, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final AppConfig config;
  final http.Client _httpClient;

  static const _timeout = Duration(seconds: 20);

  Future<Object?> sendJson(
    String method,
    String suffix, {
    String module = 'identity',
    Object? body,
    Map<String, String> headers = const {},
    Set<int> expectedStatuses = const {200},
    Map<String, String>? queryParameters,
  }) async {
    try {
      final request = http.Request(
        method,
        _apiUri(module, suffix, queryParameters: queryParameters),
      )..headers['accept'] = 'application/json';

      request.headers.addAll(headers);

      if (body != null) {
        request.headers['content-type'] = 'application/json';
        request.body = jsonEncode(body);
      }

      final streamedResponse = await _httpClient
          .send(request)
          .timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final rawBody = response.body;

      if (expectedStatuses.contains(response.statusCode)) {
        if (rawBody.isEmpty) {
          return null;
        }

        return jsonDecode(rawBody);
      }

      throw IdentityApiException.fromResponse(response.statusCode, rawBody);
    } on IdentityApiException {
      rethrow;
    } on TimeoutException {
      throw const IdentityApiException(
        message: 'Tempo limite excedido ao comunicar com a API.',
      );
    } on http.ClientException {
      throw const IdentityApiException(
        message: 'Não foi possível conectar com a API configurada.',
      );
    } on FormatException {
      throw const IdentityApiException(
        message: 'A API retornou uma resposta em formato inesperado.',
      );
    }
  }

  Future<String> sendText(
    String method,
    String suffix, {
    String module = 'identity',
    Map<String, String> headers = const {},
    Set<int> expectedStatuses = const {200},
    Map<String, String>? queryParameters,
  }) async {
    try {
      final request = http.Request(
        method,
        _apiUri(module, suffix, queryParameters: queryParameters),
      )..headers.addAll(headers);
      final streamedResponse = await _httpClient
          .send(request)
          .timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      if (expectedStatuses.contains(response.statusCode)) {
        return response.body;
      }
      throw IdentityApiException.fromResponse(
        response.statusCode,
        response.body,
      );
    } on IdentityApiException {
      rethrow;
    } on TimeoutException {
      throw const IdentityApiException(
        message: 'Tempo limite excedido ao comunicar com a API.',
      );
    } on http.ClientException {
      throw const IdentityApiException(
        message: 'Não foi possível conectar com a API configurada.',
      );
    }
  }

  Uri _apiUri(
    String module,
    String suffix, {
    Map<String, String>? queryParameters,
  }) {
    final baseSegments = config.apiBaseUrl.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    final suffixSegments = suffix
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList();
    final prefix = _modulePrefix(baseSegments, module);

    return config.apiBaseUrl.replace(
      pathSegments: [...prefix, ...suffixSegments],
      queryParameters: queryParameters?.isEmpty ?? true
          ? null
          : queryParameters,
    );
  }

  List<String> _modulePrefix(List<String> baseSegments, String module) {
    if (_endsWith(baseSegments, const ['api', 'v1'])) {
      return [...baseSegments, module];
    }

    if (baseSegments.isNotEmpty && baseSegments.last == 'api') {
      return [...baseSegments, 'v1', module];
    }

    return [...baseSegments, 'api', 'v1', module];
  }

  bool _endsWith(List<String> values, List<String> suffix) {
    if (values.length < suffix.length) {
      return false;
    }

    final offset = values.length - suffix.length;
    for (var index = 0; index < suffix.length; index += 1) {
      if (values[offset + index] != suffix[index]) {
        return false;
      }
    }

    return true;
  }
}

class IdentityApiException implements Exception {
  const IdentityApiException({
    required this.message,
    this.statusCode,
    this.responseBody,
  });

  factory IdentityApiException.fromResponse(int statusCode, String body) {
    if (body.isEmpty) {
      return IdentityApiException(
        statusCode: statusCode,
        message: 'Requisição recusada pela API.',
      );
    }

    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final message =
          decoded['message'] as String? ?? 'Requisição recusada pela API.';
      final rawFields = decoded['fields'];
      if (rawFields is Map && rawFields.isNotEmpty) {
        final details = rawFields.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join('\n');

        return IdentityApiException(
          statusCode: statusCode,
          message: '$message\n$details',
          responseBody: decoded,
        );
      }

      return IdentityApiException(
        statusCode: statusCode,
        message: message,
        responseBody: decoded,
      );
    } catch (_) {
      return IdentityApiException(
        statusCode: statusCode,
        message: 'Requisição recusada pela API.',
      );
    }
  }

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? responseBody;

  @override
  String toString() => message;
}
