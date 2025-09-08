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

  /// Closure that will be called when a Transact Interaction event occurs
  AtomicInteractionHandler? onInteraction;

  /// Closure that will be called when a Transact data request event occurs
  AtomicDataRequestHandler? onDataRequest;

  /// Response with more information when Transact completes and dismisses.
  AtomicCompletionHandler? onCompletion;

  /// Closure that will be called when a Transact Action launch event occurs
  AtomicLaunchHandler? onLaunch;

  /// Closure that will be called when a Transact auth status update event occurs
  AtomicAuthStatusUpdateHandler? onAuthStatusUpdate;

  /// Closure that will be called when a Transact task status update event occurs
  AtomicTaskStatusUpdateHandler? onTaskStatusUpdate;

  /// Present the Atomic Transact SDK
  ///   - [config] Configuration of the Transact SDK
  Future<void> presentTransact({
    required AtomicConfig configuration,
    required TransactEnvironment environment,
    AtomicPresentationStyleIOS? presentationStyleIOS,
  }) async {
    throw UnimplementedError('presentTransact() has not been implemented.');
  }

  Future<void> presentAction({
    required String id,
    required TransactEnvironment environment,
    AtomicTheme? theme,
    AtomicPresentationStyleIOS? presentationStyleIOS,
  }) async {
    throw UnimplementedError('presentAction() has not been implemented.');
  }

  Future<void> dismissTransact() async {
    throw UnimplementedError('dismissTransact() has not been implemented.');
  }

  Future<void> hideTransact() async {
    throw UnimplementedError('hideTransact() has not been implemented.');
  }
}
