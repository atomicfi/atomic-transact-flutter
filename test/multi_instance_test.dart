import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
import 'package:atomic_transact_flutter/platform_interface/atomic_method_channel.dart';
import 'package:atomic_transact_flutter/platform_interface/atomic_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_native.dart';

final _config = AtomicConfig(
  publicToken: 'token',
  tasks: [AtomicTask(operation: AtomicOperationType.deposit)],
);

Map<Object?, Object?> _taskStatus(String taskId) => <Object?, Object?>{
      'taskId': taskId,
      'product': 'deposit',
      'status': 'processing',
      'company': <Object?, Object?>{'id': 'company-1', 'name': 'Company'},
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AtomicMethodChannel platform;
  late FakeNative native;

  setUp(() {
    platform = AtomicMethodChannel();
    AtomicPlatformInterface.instance = platform;
    native = FakeNative(platform);
  });

  tearDown(() {
    native.dispose();
  });

  Future<String> present({
    AtomicInteractionHandler? onInteraction,
    AtomicDataRequestHandler? onDataRequest,
    AtomicAuthStatusUpdateHandler? onAuthStatusUpdate,
    AtomicTaskStatusUpdateHandler? onTaskStatusUpdate,
    AtomicLaunchHandler? onLaunch,
    AtomicCompletionHandler? onCompletion,
    AtomicCleanupHandler? onCleanup,
  }) {
    return platform.presentTransact(
      configuration: _config,
      environment: TransactEnvironment.sandbox,
      onInteraction: onInteraction,
      onDataRequest: onDataRequest,
      onAuthStatusUpdate: onAuthStatusUpdate,
      onTaskStatusUpdate: onTaskStatusUpdate,
      onLaunch: onLaunch,
      onCompletion: onCompletion,
      onCleanup: onCleanup,
    );
  }

  group('presentTransact', () {
    test('passes the generated instance id to native and returns it', () async {
      final id = await present();

      expect(native.calls, hasLength(1));
      final call = native.calls.single;
      expect(call.method, 'presentTransact');
      expect(call.arguments['instanceId'], id);
      expect(call.arguments['configuration'], _config.toJson());
      expect(call.arguments['apiPath'], TransactEnvironment.sandbox.apiPath);
      expect(platform.activeTransactCount, 1);
    });

    test('generates a distinct id for every launch', () async {
      final ids = <String>{};
      for (var i = 0; i < 200; i++) {
        ids.add(await present());
      }

      expect(ids, hasLength(200));
    });

    test('registers handlers before native presents', () async {
      final launches = <String>[];

      // Native emits an event while the presentTransact call is still pending.
      native.onCall = (call) async {
        await native.emit('onLaunch', call.arguments['instanceId'] as String);
        return null;
      };

      await present(onLaunch: () => launches.add('launched'));

      expect(launches, ['launched']);
    });

    test('drops the handlers and rethrows when native fails to present',
        () async {
      native.onCall = (call) async {
        throw PlatformException(code: 'PlatformError', message: 'No activity');
      };

      await expectLater(present(), throwsA(isA<PlatformException>()));
      expect(platform.activeTransactCount, 0);
    });
  });

  group('event routing', () {
    test('delivers each event only to the launch it belongs to', () async {
      final a = <String>[];
      final b = <String>[];
      final idA = await present(onTaskStatusUpdate: (u) => a.add(u.taskId));
      final idB = await present(onTaskStatusUpdate: (u) => b.add(u.taskId));

      await native.emit('onTaskStatusUpdate', idA, _taskStatus('a-1'));
      await native.emit('onTaskStatusUpdate', idB, _taskStatus('b-1'));
      await native.emit('onTaskStatusUpdate', idA, _taskStatus('a-2'));

      expect(a, ['a-1', 'a-2']);
      expect(b, ['b-1']);
    });

    test('routes every event type to the owning launch', () async {
      final events = <String>[];
      final idA = await present(
        onInteraction: (i) => events.add('interaction:${i.name}'),
        onAuthStatusUpdate: (s) => events.add('auth:${s.status}'),
        onTaskStatusUpdate: (s) => events.add('task:${s.taskId}'),
        onLaunch: () => events.add('launch'),
      );
      final other = <String>[];
      await present(
        onInteraction: (_) => other.add('interaction'),
        onAuthStatusUpdate: (_) => other.add('auth'),
        onTaskStatusUpdate: (_) => other.add('task'),
        onLaunch: () => other.add('launch'),
      );

      await native.emit('onLaunch', idA);
      await native.emit('onInteraction', idA, <Object?, Object?>{
        'name': 'Viewed Welcome Page',
      });
      await native.emit('onAuthStatusUpdate', idA, <Object?, Object?>{
        'status': 'authenticated',
        'company': <Object?, Object?>{'id': 'company-1', 'name': 'Company'},
      });
      await native.emit('onTaskStatusUpdate', idA, _taskStatus('task-1'));

      expect(events, [
        'launch',
        'interaction:Viewed Welcome Page',
        'auth:authenticated',
        'task:task-1',
      ]);
      expect(other, isEmpty);
    });

    test('delivers completions with their type, response, and error', () async {
      final completions = <String>[];
      final id = await present(
        onCompletion: (type, response, error) =>
            completions.add('${type.name}:${response?.taskId}:${error?.name}'),
      );

      await native.emit('onCompletion', id, <Object?, Object?>{
        'type': 'finished',
        'response': <Object?, Object?>{'taskId': 'task-1'},
      });
      await native.emit('onCompletion', id, <Object?, Object?>{
        'type': 'error',
        'error': 'unableToConnectToTransact',
      });

      expect(completions, [
        'finished:task-1:null',
        'error:null:unableToConnectToTransact',
      ]);
    });

    test('ignores events for an unknown or missing instance id', () async {
      final events = <String>[];
      await present(
        onTaskStatusUpdate: (_) => events.add('task'),
        onCleanup: () => events.add('cleanup'),
      );

      await native.emit('onTaskStatusUpdate', 'unknown', _taskStatus('t'));
      await native.emit('onCleanup', 'unknown');
      await native.emit('onTaskStatusUpdate', null, _taskStatus('t'));
      await native.emit('onLaunch', null);

      expect(events, isEmpty);
      expect(platform.activeTransactCount, 1);
    });

    test('logs debug messages without an instance id', () async {
      final logs = <String?>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => logs.add(message);
      addTearDown(() => debugPrint = original);

      await native.send('onDebugLog', <Object?, Object?>{'message': 'hello'});

      expect(logs, ['[AtomicTransact] hello']);
    });
  });

  group('lifecycle', () {
    test('keeps a launch after completion, until cleanup', () async {
      final events = <String>[];
      final id = await present(
        onCompletion: (type, _, __) => events.add(type.name),
        onTaskStatusUpdate: (u) => events.add('task:${u.taskId}'),
        onCleanup: () => events.add('cleanup'),
      );

      await native.emit('onCompletion', id, <Object?, Object?>{
        'type': 'closed',
        'response': <Object?, Object?>{'reason': 'task-pending'},
      });
      // Background work keeps reporting after the UI has closed.
      await native.emit('onTaskStatusUpdate', id, _taskStatus('task-1'));
      expect(platform.activeTransactCount, 1);

      await native.emit('onCleanup', id);
      await native.emit('onTaskStatusUpdate', id, _taskStatus('task-2'));
      await native.emit('onCompletion', id, <Object?, Object?>{
        'type': 'finished',
      });

      expect(events, ['closed', 'task:task-1', 'cleanup']);
      expect(platform.activeTransactCount, 0);
    });

    test('cleaning up one launch leaves the others running', () async {
      final b = <String>[];
      final idA = await present();
      final idB = await present(
        onTaskStatusUpdate: (u) => b.add(u.taskId),
        onCleanup: () => b.add('cleanup'),
      );

      await native.emit('onCleanup', idA);
      await native.emit('onTaskStatusUpdate', idB, _taskStatus('b-1'));

      expect(b, ['b-1']);
      expect(platform.activeTransactCount, 1);

      await native.emit('onCleanup', idB);
      expect(b, ['b-1', 'cleanup']);
      expect(platform.activeTransactCount, 0);
    });

    test('drops the launch even when its cleanup handler throws', () async {
      final id = await present(onCleanup: () => throw StateError('boom'));

      await expectLater(
        native.emit('onCleanup', id),
        throwsA(isA<PlatformException>()),
      );
      expect(platform.activeTransactCount, 0);
    });

    test('cleans up at most once', () async {
      var cleanups = 0;
      final id = await present(onCleanup: () => cleanups++);

      await native.emit('onCleanup', id);
      await native.emit('onCleanup', id);

      expect(cleanups, 1);
    });

    test('removeTransact stops delivering callbacks', () async {
      final events = <String>[];
      final id = await present(
        onTaskStatusUpdate: (_) => events.add('task'),
        onCleanup: () => events.add('cleanup'),
      );

      platform.removeTransact(id);
      await native.emit('onTaskStatusUpdate', id, _taskStatus('t'));
      await native.emit('onCleanup', id);

      expect(events, isEmpty);
      expect(platform.activeTransactCount, 0);
    });
  });

  group('onDataRequest', () {
    test('replies with the response for the launch that asked', () async {
      final idA = await present(
        onDataRequest: (_) => const AtomicTransactDataResponse(
          card: AtomicTransactCardData(number: '4111111111111111'),
        ),
      );
      final idB = await present(
        onDataRequest: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return const AtomicTransactDataResponse(
            identity: AtomicTransactIdentity(firstName: 'Ada'),
          );
        },
      );

      final replies = await Future.wait([
        native.emit('onDataRequest', idB, <Object?, Object?>{}),
        native.emit('onDataRequest', idA, <Object?, Object?>{}),
      ]);

      expect(replies, [
        {
          'identity': {'firstName': 'Ada'}
        },
        {
          'card': {'number': '4111111111111111'}
        },
      ]);
    });

    test('replies with an error, and keeps the launch, when the handler throws',
        () async {
      final id = await present(onDataRequest: (_) => throw StateError('boom'));

      // Both native plugins send nothing back to Transact for an error reply.
      await expectLater(
        native.emit('onDataRequest', id, <Object?, Object?>{}),
        throwsA(isA<PlatformException>()),
      );
      expect(platform.activeTransactCount, 1);
    });

    test('replies with null for an unknown or finished launch', () async {
      final id = await present(
        onDataRequest: (_) => const AtomicTransactDataResponse(
          identity: AtomicTransactIdentity(firstName: 'Ada'),
        ),
      );

      expect(
        await native.emit('onDataRequest', 'unknown', <Object?, Object?>{}),
        isNull,
      );

      await native.emit('onCleanup', id);
      expect(
        await native.emit('onDataRequest', id, <Object?, Object?>{}),
        isNull,
      );
    });
  });

  group('Atomic', () {
    test('launches again while an earlier launch is still running', () async {
      final a = <String>[];
      final b = <String>[];

      final taskA = await Atomic.transact(
        config: _config,
        onTaskStatusUpdate: (u) => a.add(u.taskId),
      );
      final taskB = await Atomic.transact(
        config: _config,
        onTaskStatusUpdate: (u) => b.add(u.taskId),
      );

      expect(native.presentedIds, [taskA.instanceId, taskB.instanceId]);
      expect(taskA.instanceId, isNot(taskB.instanceId));

      await native.emit(
          'onTaskStatusUpdate', taskA.instanceId, _taskStatus('a-1'));
      await native.emit(
          'onTaskStatusUpdate', taskB.instanceId, _taskStatus('b-1'));

      expect(a, ['a-1']);
      expect(b, ['b-1']);
    });

    test('passes onCleanup through', () async {
      final events = <String>[];
      final task = await Atomic.transact(
        config: _config,
        onCleanup: () => events.add('cleanup'),
      );

      await native.emit('onCleanup', task.instanceId);

      expect(events, ['cleanup']);
    });

    test('remove stops delivering the task callbacks', () async {
      final events = <String>[];
      final task = await Atomic.transact(
        config: _config,
        onLaunch: () => events.add('launch'),
      );

      task.remove();
      await native.emit('onLaunch', task.instanceId);

      expect(events, isEmpty);
    });

    test('close and hide call native and complete', () async {
      await Atomic.close();
      await Atomic.hide();

      expect(
        native.calls.map((call) => call.method),
        ['dismissTransact', 'hideTransact'],
      );
    });
  });
}
