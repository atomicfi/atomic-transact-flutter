import '../platform_interface/atomic_platform_interface.dart';

import 'types.dart';
import 'config.dart';

class Atomic {
  static AtomicPlatformInterface get _platform =>
      AtomicPlatformInterface.instance;

  /// Present the Atomic Transact SDK
  ///   - [config] Configuration of the Transact SDK.
  ///   - [onInteraction] Closure that will be called when a Transact Interaction event occurs.
  ///   - [onDataRequest] Closure that will be called when a Transact data request event occurs.
  ///   - [onCompletion] Response with more information when Transact completes and dismisses.
  static Future<void> transact({
    required AtomicConfig config,
    TransactEnvironment environment = TransactEnvironment.production,
    AtomicInteractionHandler? onInteraction,
    AtomicDataRequestHandler? onDataRequest,
    AtomicAuthStatusUpdateHandler? onAuthStatusUpdate,
    AtomicTaskStatusUpdateHandler? onTaskStatusUpdate,
    AtomicCompletionHandler? onCompletion,
  }) async {
    _platform.onInteraction = onInteraction;
    _platform.onDataRequest = onDataRequest;
    _platform.onAuthStatusUpdate = onAuthStatusUpdate;
    _platform.onTaskStatusUpdate = onTaskStatusUpdate;
    _platform.onCompletion = onCompletion;

    await _platform.presentTransact(
      configuration: config,
      environment: environment,
    );
  }

  static Future<void> presentAction({
    required String id,
    TransactEnvironment environment = TransactEnvironment.production,
    AtomicLaunchHandler? onLaunch,
    AtomicAuthStatusUpdateHandler? onAuthStatusUpdate,
    AtomicTaskStatusUpdateHandler? onTaskStatusUpdate,
    AtomicCompletionHandler? onCompletion,
  }) async {
    _platform.onLaunch = onLaunch;
    _platform.onAuthStatusUpdate = onAuthStatusUpdate;
    _platform.onTaskStatusUpdate = onTaskStatusUpdate;
    _platform.onCompletion = onCompletion;

    await _platform.presentAction(
      id: id,
      environment: environment,
    );
  }
}
