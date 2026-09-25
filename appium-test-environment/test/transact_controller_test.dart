import 'dart:async';

import 'package:appium_test_environment/harness.dart';
import 'package:appium_test_environment/launch_config.dart';
import 'package:appium_test_environment/transact_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _pluginChannel = MethodChannel('atomic_transact_flutter');
const _harnessChannel = MethodChannel('atomictest/harness');
const _codec = StandardMethodCodec();

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// Stands in for both native sides: the plugin's channel and the harness's.
class FakeNative {
  FakeNative() {
    _messenger.setMockMethodCallHandler(_pluginChannel, (call) async {
      pluginCalls.add(call);
      return onPluginCall?.call(call);
    });
    _messenger.setMockMethodCallHandler(_harnessChannel, (call) async {
      final arguments = call.arguments as Map<Object?, Object?>;
      switch (call.method) {
        case 'log':
          logs.add(arguments['message'] as String);
          return null;
        case 'showAlert':
          final alert = Completer<void>();
          alerts.add((
            title: arguments['title'] as String,
            button: arguments['button'] as String,
            tap: alert,
          ));
          await alert.future;
          return null;
      }
      return null;
    });
  }

  final pluginCalls = <MethodCall>[];
  final logs = <String>[];
  final alerts = <({String title, String button, Completer<void> tap})>[];

  /// Replaces the default null reply to a call from Dart to the plugin.
  Future<Object?> Function(MethodCall call)? onPluginCall;

  String get instanceId =>
      pluginCalls
              .lastWhere((call) => call.method == 'presentTransact')
              .arguments['instanceId']
          as String;

  List<String> get pluginMethods => [
    for (final call in pluginCalls) call.method,
  ];

  /// Sends a plugin event for the last launch and returns Dart's reply.
  Future<Object?> emit(String method, [Object? data]) async {
    ByteData? reply;
    await _messenger.handlePlatformMessage(
      _pluginChannel.name,
      _codec.encodeMethodCall(
        MethodCall(method, {'instanceId': instanceId, 'data': data}),
      ),
      (data) => reply = data,
    );
    await settle();
    return reply == null ? null : _codec.decodeEnvelope(reply!);
  }

  void dispose() {
    _messenger.setMockMethodCallHandler(_pluginChannel, null);
    _messenger.setMockMethodCallHandler(_harnessChannel, null);
  }
}

/// Lets queued channel messages and their replies run.
Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Map<String, String> extras([Map<String, String> overrides = const {}]) => {
  LaunchKeys.launchId: 'launch-1',
  LaunchKeys.publicToken: 'token-123',
  LaunchKeys.url: 'https://transact.atomicfi.com',
  LaunchKeys.productType: 'switch',
  LaunchKeys.scopeType: 'pay-link',
  ...overrides,
};

const _company = {'id': 'company-1', 'name': 'Netflix'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNative native;
  late Harness harness;

  setUp(() {
    native = FakeNative();
    harness = Harness();
  });

  tearDown(() => native.dispose());

  TransactController controller({bool isIOS = false}) =>
      TransactController(harness, isIOS: isIOS);

  test('presents Transact with debugging on and the suite\'s URLs', () async {
    await controller().launch(extras());
    await settle();

    final present = native.pluginCalls.single;
    expect(present.method, 'presentTransact');
    expect(present.arguments['debug'], isTrue);
    expect(present.arguments['transactPath'], 'https://transact.atomicfi.com');
    expect(present.arguments['apiPath'], apiUrl);
    expect(present.arguments['configuration']['publicToken'], 'token-123');
    expect(native.logs, containsAllInOrder(['transact-launch:launch-1']));
    expect(native.logs.join('\n'), isNot(contains('token-123')));
  });

  test('mirrors every callback in the native test app\'s wording', () async {
    await controller().launch(extras());
    await settle();

    await native.emit('onLaunch');
    await native.emit('onInteraction', {
      'name': 'Viewed Login Page',
      'value': {'company': 'Netflix'},
    });
    await native.emit('onAuthStatusUpdate', {
      'status': 'authenticated',
      'company': _company,
    });
    await native.emit('onTaskStatusUpdate', {
      'taskId': 'task-1',
      'product': 'switch',
      'status': 'completed',
      'company': _company,
    });
    await native.emit('onCompletion', {
      'type': 'finished',
      'response': {'taskId': 'task-1', 'handoff': 'authentication-success'},
    });
    await native.emit('onCompletion', {
      'type': 'closed',
      'response': {'reason': 'user-closed'},
    });
    await native.emit('onCleanup');

    expect(
      native.logs,
      containsAllInOrder([
        'RECEIVER launch',
        'callback:Launch',
        'RECEIVER interaction Viewed Login Page {"company":"Netflix"}',
        'callback:Interaction',
        'RECEIVER auth status updated AUTHENTICATED',
        'RECEIVER task status updated COMPLETED',
        'RECEIVER finish {"taskId":"task-1","handoff":"authentication-success"}',
        'Finished with Handoff: authentication-success',
        'callback:Completion',
        'RECEIVER close {"reason":"user-closed"}',
        'callback:Completion',
        'callback:Cleanup',
      ]),
    );
  });

  test('ignores a relaunch with a launch id it already launched', () async {
    final harnessController = controller();
    await harnessController.launch(extras());
    await harnessController.launch(extras());
    await settle();

    expect(native.pluginMethods, ['presentTransact']);
    expect(native.logs, contains('Ignoring duplicate launch: launch-1'));
  });

  test('logs why it cannot launch instead of launching', () async {
    await controller().launch(extras({LaunchKeys.productType: 'identify'}));
    await controller().launch({LaunchKeys.launchId: 'launch-2'});
    await settle();

    expect(native.pluginCalls, isEmpty);
    expect(
      native.logs,
      containsAllInOrder([
        'transact-launch-error:launch-1:unsupported-product',
        'transact-launch-error:launch-2:missing-config',
      ]),
    );
  });

  test('logs a failed presentation', () async {
    native.onPluginCall = (call) async => throw PlatformException(
      code: 'PlatformError',
      message: 'No keyWindow found',
    );

    await controller().launch(extras());
    await settle();

    expect(
      native.logs,
      contains('transact-launch-error:launch-1:PlatformError'),
    );
    expect(native.logs, isNot(contains('transact-launch:launch-1')));
  });

  group('DISMISS_ON_AUTH_STATUS_UPDATE_AUTHENTICATED', () {
    final dismissExtras = extras({
      LaunchKeys.customFlow: CustomFlows.dismissOnAuthenticated,
    });

    test(
      'on iOS, hides Transact, then alerts, ahead of Task Completed',
      () async {
        final hidden = Completer<void>();
        native.onPluginCall = (call) async {
          if (call.method == 'hideTransact') await hidden.future;
          return null;
        };
        await controller(isIOS: true).launch(dismissExtras);
        await settle();

        await native.emit('onAuthStatusUpdate', {
          'status': 'authenticated',
          'company': _company,
        });
        await native.emit('onTaskStatusUpdate', {
          'taskId': 'task-1',
          'product': 'switch',
          'status': 'completed',
          'company': _company,
        });
        expect(native.pluginMethods, contains('hideTransact'));
        expect(
          native.alerts,
          isEmpty,
          reason: 'nothing is shown until Transact is hidden',
        );

        hidden.complete();
        await settle();
        expect(
          [for (final alert in native.alerts) alert.title],
          [CustomFlows.dismissOnAuthenticated],
        );

        native.alerts.single.tap.complete();
        await settle();
        expect(
          [for (final alert in native.alerts) alert.title],
          [CustomFlows.dismissOnAuthenticated, 'Task Completed'],
        );
      },
    );

    test('on Android, only hides Transact', () async {
      await controller().launch(dismissExtras);
      await settle();

      await native.emit('onAuthStatusUpdate', {
        'status': 'authenticated',
        'company': _company,
      });

      expect(native.pluginMethods, ['presentTransact', 'hideTransact']);
      expect(native.alerts, isEmpty);
    });
  });

  test('on iOS, a handoff flow gets no Task Completed alert', () async {
    await controller(isIOS: true)
        .launch(extras({LaunchKeys.handoff: 'authentication-success'}));
    await settle();

    await native.emit('onTaskStatusUpdate', {
      'taskId': 'task-1',
      'product': 'switch',
      'status': 'completed',
      'company': _company,
    });

    expect(native.alerts, isEmpty);
  });

  group('onDataRequest', () {
    const request = {
      'taskId': 'task-1',
      'fields': ['card'],
    };
    final sdkExtras = extras({LaunchKeys.deferredPaymentMethodStrategy: 'sdk'});

    test('on iOS, answers once RESPOND! is tapped', () async {
      await controller(isIOS: true).launch(sdkExtras);
      await settle();

      final reply = native.emit('onDataRequest', request);
      await settle();
      expect(native.alerts.single.title, 'Received Data Request');
      expect(native.alerts.single.button, 'RESPOND!');
      expect(native.logs, isNot(contains('Sent data response')));

      native.alerts.single.tap.complete();
      expect(await reply, TransactController.dataResponse.toJson());
      expect(
        native.logs,
        containsAllInOrder([
          'RECEIVER data request [card]',
          'Sent data response',
        ]),
      );
    });

    test('on Android, answers straight away', () async {
      await controller().launch(sdkExtras);
      await settle();

      expect(
        await native.emit('onDataRequest', request),
        TransactController.dataResponse.toJson(),
      );
      expect(native.alerts, isEmpty);
      expect(
        native.logs,
        containsAllInOrder([
          'RECEIVER data request [card]',
          'Sent data response',
        ]),
      );
    });

    test('without the sdk strategy, leaves the request unanswered', () async {
      await controller().launch(extras());
      await settle();

      expect(await native.emit('onDataRequest', request), isNull);
      expect(native.logs, isNot(contains('Sent data response')));
    });
  });

  group('commands', () {
    test(
      'pause and resume go through the SDK and update PauseStatus',
      () async {
        final harnessController = controller(isIOS: true);
        final statuses = <String>[];
        harnessController.pauseStatus.addListener(
          () => statuses.add(harnessController.pauseStatus.value),
        );

        await harnessController.handleCommand(const HarnessCommand('pause'));
        await harnessController.handleCommand(const HarnessCommand('resume'));
        await harnessController.handleCommand(const HarnessCommand('pause'));
        await settle();

        expect(native.pluginMethods, [
          'pauseTransact',
          'resumeTransact',
          'pauseTransact',
        ]);
        expect(statuses, ['paused', '', 'paused']);
        expect(
          native.logs,
          containsAllInOrder([
            'Transact paused',
            'Transact resumed',
            'Transact paused',
          ]),
        );
      },
    );

    test('broadcast command names work too', () async {
      await controller().handleCommand(const HarnessCommand('PAUSE_TRANSACT'));
      await settle();

      expect(native.pluginMethods, ['pauseTransact']);
      expect(native.logs, contains('Transact paused'));
    });

    test('a failed pause says so', () async {
      native.onPluginCall = (call) async => throw PlatformException(
        code: 'PauseTransactError',
        message: 'No Transact is currently presented',
      );
      final harnessController = controller();

      await harnessController.handleCommand(
        const HarnessCommand('PAUSE_TRANSACT'),
      );
      await harnessController.handleCommand(
        const HarnessCommand('RESUME_TRANSACT'),
      );
      await settle();

      expect(harnessController.pauseStatus.value, 'resume-error');
      expect(native.logs, isNot(contains('Transact paused')));
      expect(native.logs, contains('No paused Transact to resume'));
    });

    test('other commands are reported as unsupported', () async {
      await controller().handleCommand(
        const HarnessCommand('WEBVIEW', {'url': 'https://example.com'}),
      );
      await settle();

      expect(native.pluginCalls, isEmpty);
      expect(
        native.logs,
        contains('Command WEBVIEW is not supported by the Flutter test app'),
      );
    });
  });

  test('the harness channel delivers relaunches and commands', () async {
    final launches = <Map<String, String>>[];
    final commands = <HarnessCommand>[];
    harness.launches.listen(launches.add);
    harness.commands.listen(commands.add);

    Future<void> send(String method, Object arguments) =>
        _messenger.handlePlatformMessage(
          _harnessChannel.name,
          _codec.encodeMethodCall(MethodCall(method, arguments)),
          (_) {},
        );
    await send('launch', {
      'extras': {LaunchKeys.launchId: 'launch-2'},
    });
    await send('command', {
      'name': 'PAUSE_TRANSACT',
      'extras': <String, String>{},
    });
    await settle();

    expect(launches, [
      {LaunchKeys.launchId: 'launch-2'},
    ]);
    expect(commands.single.name, 'PAUSE_TRANSACT');
  });
}
