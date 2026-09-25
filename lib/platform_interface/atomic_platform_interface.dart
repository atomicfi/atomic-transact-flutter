import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../src/config.dart';
import '../src/types.dart';
import 'atomic_method_channel.dart';

abstract class AtomicPlatformInterface extends PlatformInterface {
  AtomicPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static AtomicPlatformInterface _instance = AtomicMethodChannel();

  static AtomicPlatformInterface get instance => _instance;

  static set instance(AtomicPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Present the Atomic Transact SDK
  ///   - [config] Configuration of the Transact SDK
  ///
  /// The handlers only receive events for this launch, so presenting again
  /// does not replace the handlers of a launch that is still running. Returns
  /// the id generated for this launch.
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
    throw UnimplementedError('presentTransact() has not been implemented.');
  }

  /// Stops delivering callbacks for the launch with [instanceId].
  void removeTransact(String instanceId) {
    throw UnimplementedError('removeTransact() has not been implemented.');
  }

  Future<void> dismissTransact() async {
    throw UnimplementedError('dismissTransact() has not been implemented.');
  }

  Future<void> hideTransact() async {
    throw UnimplementedError('hideTransact() has not been implemented.');
  }

  Future<void> pauseTransact() async {
    throw UnimplementedError('pauseTransact() has not been implemented.');
  }

  Future<void> resumeTransact() async {
    throw UnimplementedError('resumeTransact() has not been implemented.');
  }
}
