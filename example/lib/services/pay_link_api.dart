import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/pay_link_account.dart';

class PayLinkApiException implements Exception {
  final String message;
  final int? statusCode;

  const PayLinkApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      statusCode == null ? message : 'HTTP $statusCode: $message';
}

/// Fetches the Pay Link accounts behind a public token, with their actions.
Future<List<PayLinkAccount>> fetchPayLinkAccounts({
  required String apiPath,
  required String publicToken,
}) async {
  final base = apiPath.trim().replaceAll(RegExp(r'/+$'), '');
  final uri = Uri.tryParse('$base/pay-link/accounts');
  if (uri == null ||
      !(uri.isScheme('http') || uri.isScheme('https')) ||
      uri.host.isEmpty) {
    throw PayLinkApiException('Invalid API URL "$apiPath"');
  }

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.getUrl(uri);
    try {
      request.headers.set('x-public-token', publicToken.trim());
    } on FormatException {
      throw const PayLinkApiException(
          'The public token has characters that can\'t be sent');
    }
    request.headers.set('x-api-version', 'v2');

    final response = await request.close().timeout(const Duration(seconds: 30));
    final Object? json;
    try {
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode > 299) {
        throw PayLinkApiException(_errorMessage(body),
            statusCode: response.statusCode);
      }
      json = jsonDecode(body);
    } on FormatException {
      throw const PayLinkApiException('The response is not valid JSON');
    }

    final accounts = json is Map ? json['accounts'] : null;
    if (accounts is! List) {
      throw const PayLinkApiException('Response has no accounts list');
    }
    return accounts
        .whereType<Map>()
        .map((a) => PayLinkAccount.fromJson(Map<String, dynamic>.from(a)))
        .toList();
  } on IOException catch (e) {
    // Covers socket, TLS and HTTP protocol failures.
    throw PayLinkApiException('Network error: $e');
  } on TimeoutException {
    throw const PayLinkApiException('The request timed out');
  } finally {
    // Forced, so a request that failed before it was sent doesn't keep its
    // connection open.
    client.close(force: true);
  }
}

String _errorMessage(String body) {
  try {
    final json = jsonDecode(body);
    if (json is Map && json['message'] != null) {
      return json['message'].toString();
    }
  } on FormatException {
    // Not JSON; fall through to the raw body.
  }
  return body.length > 200 ? '${body.substring(0, 200)}…' : body;
}
