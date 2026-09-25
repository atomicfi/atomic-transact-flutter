import 'package:atomic_transact_flutter_example/models/pay_link_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayLinkAccount.fromJson', () {
    test('reads the company name and account and bill actions', () {
      final account = PayLinkAccount.fromJson({
        '_id': 'account-1',
        'company': {'_id': 'company-1', 'name': 'Netflix'},
        'actions': [
          {'actionId': 'view', 'type': 'view-account'},
        ],
        'bills': [
          {
            'name': 'Netflix Standard',
            'actions': [
              {'actionId': 'view', 'type': 'view-account'},
              {'actionId': 'cancel', 'type': 'cancel-plan'},
            ],
          },
        ],
      });

      expect(account.id, 'account-1');
      expect(account.name, 'Netflix');
      expect(account.actions.map((a) => a.type), ['view-account']);
      expect(account.bills, hasLength(1));
      expect(account.bills.single.name, 'Netflix Standard');
      // The account-level action the API repeats on the bill is listed once.
      expect(account.bills.single.actions.map((a) => a.id), ['cancel']);
      expect(account.hasActions, isTrue);
    });

    test('drops bills with no actions of their own', () {
      final account = PayLinkAccount.fromJson({
        'company': {'name': 'Walmart'},
        'actions': [
          {'actionId': 'refresh', 'type': 'refresh'},
        ],
        'bills': [
          {
            'name': 'Walmart+',
            'actions': [
              {'actionId': 'refresh', 'type': 'refresh'},
            ],
          },
          {'name': 'Empty'},
        ],
      });

      expect(account.bills, isEmpty);
    });

    test('tolerates missing fields', () {
      final account = PayLinkAccount.fromJson({
        'actions': [
          {'type': 'no-id'},
          {'actionId': 'id-only'},
        ],
      });

      expect(account.name, 'Account');
      expect(account.actions.single.id, 'id-only');
      expect(account.actions.single.type, 'unknown');
    });

    test('has no actions when the API returns none', () {
      final account = PayLinkAccount.fromJson({
        'company': {'name': 'T-Mobile'},
        'actions': [],
        'bills': [],
      });

      expect(account.hasActions, isFalse);
    });
  });
}
