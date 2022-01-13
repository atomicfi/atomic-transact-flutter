import '../platform_interface/atomic_platform_interface.dart';

import 'types.dart';
import 'config.dart';

class Atomic {
  static AtomicPlatformInterface get _platform =>
      AtomicPlatformInterface.instance;

  /// Closure that will be called when a Transact Interaction event occurs
  static void onInteraction(AtomicInteractionHandler listener) =>
      _platform.onInteraction = listener;

  /// Closure that will be called when a Transact data request event occurs
  static void onDataRequest(AtomicDataRequestHandler listener) =>
      _platform.onDataRequest = listener;

  /// Response with more information when Transact completes and dismisses.
  static void onCompletion(AtomicCompletionHandler listener) =>
      _platform.onCompletion = listener;

  /// Present the Atomic Transact SDK
  ///   - [config] Configuration of the Transact SDK
  ///   - [environment] Environment to use for Transact. Defaults to `.production`
  static Future<void> presentTransact({
    required AtomicConfig configuration,
    AtomicEnvironment environment = AtomicEnvironment.production,
  }) async {
    await _platform.presentTransact(
      configuration: configuration,
      environment: environment,
    );
  }
}
