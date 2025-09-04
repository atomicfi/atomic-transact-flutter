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
    required TransactEnvironment environment,
    AtomicPresentationStyleIOS? presentationStyleIOS,
  }) async {
    await _channel.invokeMethod(
      'presentTransact',
      {
        'configuration': configuration.toJson(),
        'transactPath': environment.transactPath,
        'apiPath': environment.apiPath,
        'presentationStyleIOS': presentationStyleIOS?.name,
      },
    );
  }

  /// Present the Atomic Action SDK
  ///   - [id] The id of the action to present
  @override
  Future<void> presentAction({
    required String id,
    required TransactEnvironment environment,
    AtomicTheme? theme,
    AtomicPresentationStyleIOS? presentationStyleIOS,
  }) async {
    await _channel.invokeMethod('presentAction', {
      'id': id,
      'transactPath': environment.transactPath,
      'apiPath': environment.apiPath,
      'theme': theme?.toJson(),
      'presentationStyleIOS': presentationStyleIOS?.name,
    });
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
        final response = responseData != null
            ? AtomicTransactResponse.fromJson(responseData)
            : null;

        final errorName = call.arguments['error'];
        final error = errorName != null
            ? AtomicTransactError.values.byName(errorName)
            : null;

        onCompletion?.call(type, response, error);
        break;

      case 'onLaunch':
        onLaunch?.call();
        break;

      case 'onAuthStatusUpdate':
        final authData = call.arguments['auth'];
        onAuthStatusUpdate?.call(
          AtomicTransactAuthStatusUpdate.fromJson(
            Map<String, dynamic>.from(authData),
          ),
        );
        break;

      case 'onTaskStatusUpdate':
        final taskData = call.arguments['task'];
        final mappedData = Map<String, dynamic>.from(taskData);
        final update = AtomicTransactTaskStatusUpdate.fromJson(mappedData);
        onTaskStatusUpdate?.call(update);
        break;

      default:
        throw MissingPluginException(
            '${call.method} was invoked but has no handler');
    }
  }
}
