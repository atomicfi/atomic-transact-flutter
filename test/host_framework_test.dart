import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
import 'package:atomic_transact_flutter/platform_interface/atomic_method_channel.dart';
import 'package:atomic_transact_flutter/src/version.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_native.dart';

final _config = AtomicConfig(
  publicToken: 'token',
  tasks: [AtomicTask(operation: AtomicOperationType.deposit)],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The arguments [platform] sends to the native `presentTransact`.
  Future<Map<Object?, Object?>> presentArguments(
      AtomicMethodChannel platform) async {
    final native = FakeNative(platform);
    addTearDown(native.dispose);

    await platform.presentTransact(
      configuration: _config,
      environment: TransactEnvironment.sandbox,
    );

    return native.calls.single.arguments as Map<Object?, Object?>;
  }

  test('sends the Flutter version alongside the plugin version', () async {
    final arguments =
        await presentArguments(AtomicMethodChannel(flutterVersion: '3.38.1'));

    expect(arguments['flutterVersion'], '3.38.1');
    expect(arguments['pluginVersion'], packageVersion);
  });

  // Flutter older than 3.32 doesn't set FLUTTER_VERSION.
  test('sends an unknown Flutter version as null', () async {
    final arguments =
        await presentArguments(AtomicMethodChannel(flutterVersion: ''));

    expect(arguments.containsKey('flutterVersion'), isTrue);
    expect(arguments['flutterVersion'], isNull);
    expect(arguments['pluginVersion'], packageVersion);
  });

  test('reads the Flutter version from the FLUTTER_VERSION dart-define',
      () async {
    const define = String.fromEnvironment('FLUTTER_VERSION');

    final arguments = await presentArguments(AtomicMethodChannel());

    expect(arguments['flutterVersion'], define.isEmpty ? null : define);
  });
}
