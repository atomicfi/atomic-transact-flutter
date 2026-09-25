import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

Map<Object?, Object?> _update([Map<Object?, Object?> extra = const {}]) => {
      'taskId': 'task-1',
      'product': 'action',
      'status': 'processing',
      'company': <Object?, Object?>{'id': 'company-1', 'name': 'Netflix'},
      ...extra,
    };

void main() {
  group('AtomicTransactTaskStatusUpdate.fromJson', () {
    test('reads the action type of an action task', () {
      final update = AtomicTransactTaskStatusUpdate.fromJson(
        _update({'actionType': 'cancel-plan'}),
      );

      expect(update.actionType, 'cancel-plan');
    });

    test('leaves the action type null for other tasks', () {
      final update = AtomicTransactTaskStatusUpdate.fromJson(_update());

      expect(update.actionType, isNull);
    });
  });
}
