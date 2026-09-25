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
  ///     Return an [AtomicTransactDataResponse] to send the requested data back to Transact.
  ///   - [onLaunch] Closure that will be called when a Transact launch event occurs.
  ///   - [onCompletion] Response with more information when Transact completes and dismisses.
  ///     A task can keep sending status updates after this.
  ///   - [onCleanup] Closure that will be called once the launch has ended for good. No further
  ///     callbacks are delivered for the launch after this one.
  ///   - [presentationStyleIOS] iOS presentation style (only applicable on iOS).
  ///
  /// Every call is its own launch with its own callbacks, so calling this again
  /// does not replace the callbacks of a launch that is still running. It also
  /// means a second call launches a second Transact, even while one is open.
  /// Returns an [AtomicTransactTask] for the launch.
  ///
  /// Throws a `PlatformException` if Transact can't be presented, for example
  /// when there is no activity or window to present it from.
  static Future<AtomicTransactTask> transact({
    required AtomicConfig config,
    TransactEnvironment environment = TransactEnvironment.production,
    AtomicInteractionHandler? onInteraction,
    AtomicDataRequestHandler? onDataRequest,
    AtomicAuthStatusUpdateHandler? onAuthStatusUpdate,
    AtomicTaskStatusUpdateHandler? onTaskStatusUpdate,
    AtomicLaunchHandler? onLaunch,
    AtomicCompletionHandler? onCompletion,
    AtomicCleanupHandler? onCleanup,
    AtomicPresentationStyleIOS? presentationStyleIOS,
    bool debug = false,
  }) async {
    final platform = _platform;
    final instanceId = await platform.presentTransact(
      configuration: config,
      environment: environment,
      presentationStyleIOS: presentationStyleIOS,
      debug: debug,
      onInteraction: onInteraction,
      onDataRequest: onDataRequest,
      onAuthStatusUpdate: onAuthStatusUpdate,
      onTaskStatusUpdate: onTaskStatusUpdate,
      onLaunch: onLaunch,
      onCompletion: onCompletion,
      onCleanup: onCleanup,
    );

    return AtomicTransactTask._(instanceId, platform);
  }

  /// Closes every launch that hasn't finished or closed yet, including hidden
  /// and paused ones. Those launches get `onCleanup`, but not `onCompletion`.
  /// Launches that already finished or closed keep running until they clean up
  /// on their own.
  static Future<void> close() async {
    await _platform.dismissTransact();
  }

  /// Hides every Transact that is on screen. The launches keep running.
  static Future<void> hide() async {
    await _platform.hideTransact();
  }

  /// Hides any currently open Transact views and returns a reference to present them again later.
  /// Call [PausedTransactRef.resume] to present the Transact view again.
  /// Throws [PauseTransactException] if no Transact is currently presented.
  static Future<PausedTransactRef> pauseTransact() async {
    await _platform.pauseTransact();
    return PausedTransactRef._(_platform);
  }
}

/// A single launch of Transact, returned by [Atomic.transact].
class AtomicTransactTask {
  /// Id generated for this launch. Every event for the launch is routed by it.
  final String instanceId;

  final AtomicPlatformInterface _platform;

  AtomicTransactTask._(this.instanceId, this._platform);

  /// Stops delivering this launch's callbacks. This does not close Transact.
  /// [Atomic.close] closes every open launch, not just this one.
  void remove() {
    _platform.removeTransact(instanceId);
  }
}

/// A reference to a paused Transact session. Call [resume] to present the Transact view again.
class PausedTransactRef {
  final AtomicPlatformInterface _platform;

  PausedTransactRef._(this._platform);

  /// Presents the paused Transact view again.
  Future<void> resume() async {
    await _platform.resumeTransact();
  }
}
