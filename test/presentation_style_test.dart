import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
import 'package:atomic_transact_flutter/platform_interface/atomic_method_channel.dart';
import 'package:atomic_transact_flutter/platform_interface/atomic_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_native.dart';

final _config = AtomicConfig(
  publicToken: 'token',
  tasks: [AtomicTask(operation: AtomicOperationType.deposit)],
);

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

  Map<Object?, Object?> presentArguments() =>
      native.calls.single.arguments as Map<Object?, Object?>;

  test('sends presentationStyleAndroid by name', () async {
    for (final style in AtomicPresentationStyleAndroid.values) {
      native.calls.clear();
      await Atomic.transact(config: _config, presentationStyleAndroid: style);

      expect(presentArguments()['presentationStyleAndroid'], style.name);
    }
  });

  test('sends no presentationStyleAndroid when none is set', () async {
    await Atomic.transact(config: _config);

    final arguments = presentArguments();
    expect(arguments.containsKey('presentationStyleAndroid'), isTrue);
    expect(arguments['presentationStyleAndroid'], isNull);
  });

  test('sends both platform styles independently', () async {
    await Atomic.transact(
      config: _config,
      presentationStyleIOS: AtomicPresentationStyleIOS.fullScreen,
      presentationStyleAndroid: AtomicPresentationStyleAndroid.formSheet,
    );

    final arguments = presentArguments();
    expect(arguments['presentationStyleIOS'], 'fullScreen');
    expect(arguments['presentationStyleAndroid'], 'formSheet');
  });
}
