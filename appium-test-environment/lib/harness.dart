import 'dart:async';

import 'package:flutter/services.dart';

/// A command sent by the conformance suite: an `am broadcast` on Android
/// (`PAUSE_TRANSACT`, `RESUME_TRANSACT`, ...) or an `atomictest://<command>`
/// URL on iOS (`pause`, `resume`, ...).
class HarnessCommand {
  const HarnessCommand(this.name, [this.extras = const {}]);

  final String name;
  final Map<String, String> extras;
}

/// Dart side of the `atomictest/harness` channel.
///
/// The native code only moves data between the suite and Dart: launch
/// parameters and commands in, log lines and alerts out. Transact itself is
/// driven from Dart through the plugin, which is what the suite is testing.
class Harness {
  Harness({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('atomictest/harness') {
    _channel.setMethodCallHandler(_onNativeCall);
  }

  final MethodChannel _channel;
  final _launches = StreamController<Map<String, String>>.broadcast();
  final _commands = StreamController<HarnessCommand>.broadcast();

  /// Launch parameters of a start that reached the running app (Android only;
  /// a cold start reads them with [getLaunchExtras]).
  Stream<Map<String, String>> get launches => _launches.stream;

  /// Commands the suite sends while Transact is running.
  Stream<HarnessCommand> get commands => _commands.stream;

  /// The `TRANSACT_*` values the app was started with: intent extras on
  /// Android, launch environment variables on iOS.
  Future<Map<String, String>> getLaunchExtras() async {
    final extras = await _channel.invokeMapMethod<String, String>(
      'getLaunchExtras',
    );
    return extras ?? const {};
  }

  /// Writes [message] to the platform log under the `AppiumTestEnvironment`
  /// tag, where the suite's `waitForLogs` looks for it. Not `print` or
  /// `debugPrint`: on Android both land under the `flutter` tag, and
  /// `debugPrint` is throttled and shared with the SDK's own debug output.
  Future<void> log(String message) =>
      _channel.invokeMethod<void>('log', {'message': message});

  /// Presents a native alert and completes once its [button] is tapped.
  /// iOS only: the iOS specs find the host app's alerts by title and button.
  Future<void> showAlert(
    String title, {
    String? message,
    String button = 'Okay',
  }) => _channel.invokeMethod<void>('showAlert', {
    'title': title,
    'message': message,
    'button': button,
  });

  Future<Object?> _onNativeCall(MethodCall call) async {
    final arguments = call.arguments as Map<Object?, Object?>? ?? const {};
    switch (call.method) {
      case 'launch':
        _launches.add(_strings(arguments['extras']));
        return null;
      case 'command':
        _commands.add(
          HarnessCommand(
            arguments['name'] as String? ?? '',
            _strings(arguments['extras']),
          ),
        );
        return null;
      default:
        throw MissingPluginException('${call.method} has no handler');
    }
  }

  static Map<String, String> _strings(Object? value) => {
    for (final entry in (value as Map<Object?, Object?>? ?? const {}).entries)
      '${entry.key}': '${entry.value}',
  };
}
