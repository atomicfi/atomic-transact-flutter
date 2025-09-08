import '../platform_interface/atomic_platform_interface.dart';
import '../src/events.dart';

import 'types.dart';
import 'config.dart';

class Atomic {
  static bool _isLoading = false;
  static AtomicPlatformInterface get _platform =>
      AtomicPlatformInterface.instance;

  /// Present the Atomic Transact SDK
  ///   - [config] Configuration of the Transact SDK.
  ///   - [onInteraction] Closure that will be called when a Transact Interaction event occurs.
  ///   - [onDataRequest] Closure that will be called when a Transact data request event occurs.
  ///   - [onCompletion] Response with more information when Transact completes and dismisses.
  ///   - [presentationStyleIOS] iOS presentation style (only applicable on iOS).
  static Future<void> transact({
    required AtomicConfig config,
    TransactEnvironment environment = TransactEnvironment.production,
    AtomicInteractionHandler? onInteraction,
    AtomicDataRequestHandler? onDataRequest,
    AtomicAuthStatusUpdateHandler? onAuthStatusUpdate,
    AtomicTaskStatusUpdateHandler? onTaskStatusUpdate,
    AtomicCompletionHandler? onCompletion,
    AtomicPresentationStyleIOS? presentationStyleIOS,
  }) async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;

    _platform.onInteraction = onInteraction;
    _platform.onDataRequest = onDataRequest;
    _platform.onAuthStatusUpdate = onAuthStatusUpdate;
    _platform.onTaskStatusUpdate = onTaskStatusUpdate;
    _platform.onCompletion = (
      AtomicTransactCompletionType type,
      AtomicTransactResponse? response,
      AtomicTransactError? error,
    ) {
      _isLoading = false;
      if (onCompletion != null) {
        return onCompletion(type, response, error);
      }
    };

    await _platform.presentTransact(
      configuration: config,
      environment: environment,
      presentationStyleIOS: presentationStyleIOS,
    );
  }

  static Future<void> presentAction({
    required String id,
    TransactEnvironment environment = TransactEnvironment.production,
    AtomicLaunchHandler? onLaunch,
    AtomicAuthStatusUpdateHandler? onAuthStatusUpdate,
    AtomicTaskStatusUpdateHandler? onTaskStatusUpdate,
    AtomicCompletionHandler? onCompletion,
    AtomicTheme? theme,
    AtomicPresentationStyleIOS? presentationStyleIOS,
  }) async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;

    _platform.onLaunch = () {
      _isLoading = false;
      if (onLaunch != null) {
        return onLaunch();
      }
    };
    _platform.onAuthStatusUpdate = onAuthStatusUpdate;
    _platform.onTaskStatusUpdate = onTaskStatusUpdate;
    _platform.onCompletion = onCompletion;

    await _platform.presentAction(
        id: id,
        environment: environment,
        theme: theme,
        presentationStyleIOS: presentationStyleIOS);
  }

  static Future<void> close() async {
    _isLoading = false;
    await _platform.dismissTransact();
  }

  static Future<void> hide() async {
    _isLoading = false;
    await _platform.hideTransact();
  }
}
