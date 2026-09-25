import 'package:atomic_transact_flutter/src/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../src/config.dart';
import '../src/types.dart';
import '../src/version.dart';
import 'atomic_platform_interface.dart';

class AtomicMethodChannel extends AtomicPlatformInterface {
  final MethodChannel _channel = const MethodChannel('atomic_transact_flutter');

  /// Handlers for every launch that is still running, keyed by instance id.
  ///
  /// An entry is only dropped on `onCleanup`, or when the launch fails or is
  /// removed. `onCompletion` is not terminal: a task can keep sending status
  /// updates after its UI has closed.
  final Map<String, _TransactHandlers> _transacts = {};

  int _instanceCounter = 0;

  MethodChannel get channel => _channel;

  AtomicMethodChannel() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  /// Number of launches whose handlers are still registered.
  @visibleForTesting
  int get activeTransactCount => _transacts.length;

  /// Present the Atomic Transact SDK
  ///   - [config] Configuration of the Transact SDK
  @override
  Future<String> presentTransact({
    required AtomicConfig configuration,
    required TransactEnvironment environment,
    AtomicPresentationStyleIOS? presentationStyleIOS,
    bool debug = false,
    AtomicInteractionHandler? onInteraction,
    AtomicDataRequestHandler? onDataRequest,
    AtomicAuthStatusUpdateHandler? onAuthStatusUpdate,
    AtomicTaskStatusUpdateHandler? onTaskStatusUpdate,
    AtomicLaunchHandler? onLaunch,
    AtomicCompletionHandler? onCompletion,
    AtomicCleanupHandler? onCleanup,
  }) async {
    final instanceId = _createInstanceId();

    // Registered before the native call, so an event sent while Transact is
    // being presented can't arrive before its handlers exist.
    _transacts[instanceId] = _TransactHandlers(
      onInteraction: onInteraction,
      onDataRequest: onDataRequest,
      onAuthStatusUpdate: onAuthStatusUpdate,
      onTaskStatusUpdate: onTaskStatusUpdate,
      onLaunch: onLaunch,
      onCompletion: onCompletion,
      onCleanup: onCleanup,
    );

    try {
      await _channel.invokeMethod(
        'presentTransact',
        {
          'instanceId': instanceId,
          'configuration': configuration.toJson(),
          'transactPath': environment.transactPath,
          'apiPath': environment.apiPath,
          'presentationStyleIOS': presentationStyleIOS?.name,
          'pluginVersion': packageVersion,
          'debug': debug,
        },
      );
    } catch (_) {
      // Nothing was presented, so no onCleanup will ever arrive for this id.
      _transacts.remove(instanceId);
      rethrow;
    }

    return instanceId;
  }

  @override
  void removeTransact(String instanceId) {
    _transacts.remove(instanceId);
  }

  @override
  Future<void> dismissTransact() async {
    await _channel.invokeMethod('dismissTransact');
  }

  @override
  Future<void> hideTransact() async {
    await _channel.invokeMethod('hideTransact');
  }

  @override
  Future<void> pauseTransact() async {
    await _channel.invokeMethod('pauseTransact');
  }

  @override
  Future<void> resumeTransact() async {
    await _channel.invokeMethod('resumeTransact');
  }

  /// The counter keeps ids unique within a run. The timestamp keeps a new run
  /// from reusing an id that native code still holds from before a hot
  /// restart, which would send that old launch's events to the new one.
  String _createInstanceId() {
    _instanceCounter += 1;
    return 'flutter-transact-$_instanceCounter-'
        '${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Handles receiving messages on the [MethodChannel]
  Future<dynamic> _onMethodCall(MethodCall call) async {
    if (call.method == 'onDebugLog') {
      // Logs aren't tied to a launch: both native SDKs forward them through a
      // single global sink.
      final message = call.arguments['message'] as String? ?? '';
      debugPrint('[AtomicTransact] $message');
      return null;
    }

    // Every other event arrives as an envelope: {instanceId, data}. Events for
    // a launch that has ended, or that this run never started, are dropped.
    final arguments = call.arguments as Map<Object?, Object?>?;
    final instanceId = arguments?['instanceId'];
    final data = arguments?['data'];
    final handlers = _transacts[instanceId];

    switch (call.method) {
      case 'onInteraction':
        handlers?.onInteraction
            ?.call(AtomicTransactInteraction.fromJson(data));
        break;

      case 'onDataRequest':
        // Request/response: whatever the handler returns is sent straight back
        // to the native SDK as the reply to this call. Returning null leaves
        // Transact waiting, which is the same as having no handler at all.
        final handler = handlers?.onDataRequest;
        if (handler == null) {
          return null;
        }

        final response =
            await handler(AtomicTransactDataRequest.fromJson(data));
        return response?.toJson();

      case 'onCompletion':
        final handler = handlers?.onCompletion;
        if (handler == null) {
          break;
        }

        final completion = data as Map<Object?, Object?>;
        final typeName = completion['type'] as String;
        final type = AtomicTransactCompletionType.values.byName(typeName);

        final responseData = completion['response'];
        final response = responseData != null
            ? AtomicTransactResponse.fromJson(responseData)
            : null;

        final errorName = completion['error'] as String?;
        final error = errorName != null
            ? AtomicTransactError.values.byName(errorName)
            : null;

        handler(type, response, error);
        break;

      case 'onLaunch':
        handlers?.onLaunch?.call();
        break;

      case 'onAuthStatusUpdate':
        handlers?.onAuthStatusUpdate?.call(
          AtomicTransactAuthStatusUpdate.fromJson(
            Map<String, dynamic>.from(data as Map<Object?, Object?>),
          ),
        );
        break;

      case 'onTaskStatusUpdate':
        handlers?.onTaskStatusUpdate?.call(
          AtomicTransactTaskStatusUpdate.fromJson(
            Map<String, dynamic>.from(data as Map<Object?, Object?>),
          ),
        );
        break;

      case 'onCleanup':
        // Terminal. The entry is dropped before calling out, so a handler that
        // throws can't keep it alive.
        _transacts.remove(instanceId);
        handlers?.onCleanup?.call();
        break;

      default:
        throw MissingPluginException(
            '${call.method} was invoked but has no handler');
    }
  }
}

/// The callbacks passed to a single [AtomicMethodChannel.presentTransact] call.
class _TransactHandlers {
  final AtomicInteractionHandler? onInteraction;
  final AtomicDataRequestHandler? onDataRequest;
  final AtomicAuthStatusUpdateHandler? onAuthStatusUpdate;
  final AtomicTaskStatusUpdateHandler? onTaskStatusUpdate;
  final AtomicLaunchHandler? onLaunch;
  final AtomicCompletionHandler? onCompletion;
  final AtomicCleanupHandler? onCleanup;

  const _TransactHandlers({
    this.onInteraction,
    this.onDataRequest,
    this.onAuthStatusUpdate,
    this.onTaskStatusUpdate,
    this.onLaunch,
    this.onCompletion,
    this.onCleanup,
  });
}
