import 'package:atomic_transact_flutter/src/events.dart';
import 'package:flutter/services.dart';

import '../src/config.dart';
import '../src/types.dart';
import 'atomic_platform_interface.dart';

class AtomicMethodChannel extends AtomicPlatformInterface {
  final MethodChannel _channel = const MethodChannel('atomic_transact_flutter');

  MethodChannel get channel => _channel;

  AtomicMethodChannel() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  /// Present the Atomic Transact SDK
  ///   - [config] Configuration of the Transact SDK
  @override
  Future<void> presentTransact({
    required AtomicConfig configuration,
  }) async {
    await _channel.invokeMethod(
      'presentTransact',
      {
        'configuration': configuration.toJson(),
      },
    );
  }

  @override
  Future<void> dismissTransact() async {
    await _channel.invokeMethod('dismissTransact');
  }

  /// Handles receiving messages on the [MethodChannel]
  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onInteraction':
        final interaction = call.arguments['interaction'];
        onInteraction?.call(AtomicTransactInteraction.fromJson(interaction));
        break;

      case 'onDataRequest':
        final request = call.arguments['request'];
        onDataRequest?.call(AtomicTransactDataRequest.fromJson(request));
        break;

      case 'onCompletion':
        final typeName = call.arguments['type'];
        final type = AtomicTransactCompletionType.values.byName(typeName);

        final responseData = call.arguments['response'];
        final response =
            responseData != null ? AtomicTransactResponse.fromJson(responseData) : null;

        final errorName = call.arguments['error'];
        final error = errorName != null ? AtomicTransactError.values.byName(errorName) : null;

        onCompletion?.call(type, response, error);
        break;

      default:
        throw MissingPluginException('${call.method} was invoked but has no handler');
    }
  }
}
