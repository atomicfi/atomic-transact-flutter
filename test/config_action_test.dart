import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AtomicTask.action', () {
    test('serializes the action id and headless flag the native SDKs expect',
        () {
      final json =
          AtomicTask.action(actionId: 'action-1', headless: true).toJson();

      expect(json, {
        'operation': 'action',
        'action': {'id': 'action-1'},
        'headless': true,
      });
    });

    test('omits headless when unset', () {
      final json = AtomicTask.action(actionId: 'action-1').toJson();

      expect(json, {
        'operation': 'action',
        'action': {'id': 'action-1'},
      });
    });

    test('is included in AtomicConfig JSON output', () {
      final config = AtomicConfig(
        publicToken: 'token',
        scope: 'pay-link',
        tasks: [AtomicTask.action(actionId: 'action-1', headless: false)],
      );

      expect(config.toJson()['tasks'], [
        {
          'operation': 'action',
          'action': {'id': 'action-1'},
          'headless': false,
        }
      ]);
    });
  });

  test('other tasks leave action and headless out', () {
    final json = AtomicTask(operation: AtomicOperationType.deposit).toJson();

    expect(json.containsKey('action'), isFalse);
    expect(json.containsKey('headless'), isFalse);
  });
}
