import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AtomicDeeplink.step(DeeplinkStep.account)', () {
    test('serializes account step with accountId', () {
      final deeplink = AtomicDeeplink.step(
        DeeplinkStep.account(accountId: 'abc123'),
      );

      expect(deeplink.toJson(), {
        'step': 'account',
        'accountId': 'abc123',
      });
    });

    test('omits companyId, connectorId, and other unrelated fields', () {
      final json = AtomicDeeplink.step(
        DeeplinkStep.account(accountId: 'abc123'),
      ).toJson();

      expect(json.containsKey('companyId'), isFalse);
      expect(json.containsKey('connectorId'), isFalse);
      expect(json.containsKey('companyName'), isFalse);
      expect(json.containsKey('singleSwitch'), isFalse);
      expect(json.containsKey('payments'), isFalse);
      expect(json.containsKey('app'), isFalse);
    });

    test('is included in AtomicConfig JSON output', () {
      final config = AtomicConfig(
        publicToken: 'token',
        product: AtomicProductType.deposit,
        deeplink: AtomicDeeplink.step(
          DeeplinkStep.account(accountId: 'abc123'),
        ),
      );

      expect(config.toJson()['deeplink'], {
        'step': 'account',
        'accountId': 'abc123',
      });
    });
  });

  group('existing deeplink steps remain unchanged', () {
    test('addCard step serializes without accountId', () {
      final json = AtomicDeeplink.step(DeeplinkStep.addCard).toJson();

      expect(json, {'step': 'add-card'});
    });

    test('loginCompany step serializes with companyId', () {
      final json = AtomicDeeplink.step(
        DeeplinkStep.loginCompany(companyId: 'company-1'),
      ).toJson();

      expect(json, {
        'step': 'login-company',
        'companyId': 'company-1',
      });
    });

    test('payNow app serializes with payments and accountId', () {
      final json = AtomicDeeplink.app(
        DeeplinkApp.payNow(payments: ['p1'], accountId: 'acct-1'),
      ).toJson();

      expect(json, {
        'app': 'pay-now',
        'payments': ['p1'],
        'accountId': 'acct-1',
      });
    });
  });
}
