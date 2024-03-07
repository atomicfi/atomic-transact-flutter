import '../platform_interface/atomic_platform_interface.dart';

import 'types.dart';
import 'config.dart';

class Atomic {
  static AtomicPlatformInterface get _platform => AtomicPlatformInterface.instance;

  /// Present the Atomic Transact SDK
  ///   - [config] Configuration of the Transact SDK.
  ///   - [onInteraction] Closure that will be called when a Transact Interaction event occurs.
  ///   - [onDataRequest] Closure that will be called when a Transact data request event occurs.
  ///   - [onCompletion] Response with more information when Transact completes and dismisses.
  static Future<void> transact({
    required AtomicConfig config,
    AtomicInteractionHandler? onInteraction,
    AtomicDataRequestHandler? onDataRequest,
    AtomicCompletionHandler? onCompletion,
  }) async {
    _platform.onInteraction = onInteraction;
    _platform.onDataRequest = onDataRequest;
    _platform.onCompletion = onCompletion;

    await _platform.presentTransact(
      configuration: config,
    );
  }

  static Future<void> close() async {
    await _platform.dismissTransact();
  }
}
