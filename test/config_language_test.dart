import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

AtomicConfig _config({String? language}) => AtomicConfig(
      publicToken: 'token',
      tasks: [AtomicTask(operation: AtomicOperationType.deposit)],
      language: language,
    );

void main() {
  // The native SDKs parse and resolve locales, so Dart must send the code as given.
  test('serializes language codes and locales unchanged', () {
    for (final language in ['pt', 'pt-BR', 'en_CA']) {
      expect(_config(language: language).toJson()['language'], language);
    }
  });

  test('omits language when unset, so the native SDKs use the device language', () {
    expect(_config().toJson().containsKey('language'), isFalse);
  });
}
