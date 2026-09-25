import 'package:atomic_transact_flutter/platform_interface/atomic_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the native side of the plugin's method channel.
class FakeNative {
  FakeNative(this.platform) {
    _messenger.setMockMethodCallHandler(platform.channel, (call) async {
      calls.add(call);
      return onCall?.call(call);
    });
  }

  static const _codec = StandardMethodCodec();

  final AtomicMethodChannel platform;

  /// Every call Dart made to the native side, in order.
  final calls = <MethodCall>[];

  /// Replaces the default null reply to a call from Dart.
  Future<Object?> Function(MethodCall call)? onCall;

  TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Instance ids Dart passed to `presentTransact`, in order.
  List<String> get presentedIds => calls
      .where((call) => call.method == 'presentTransact')
      .map((call) => call.arguments['instanceId'] as String)
      .toList();

  void dispose() {
    _messenger.setMockMethodCallHandler(platform.channel, null);
  }

  /// Sends [method] to Dart for [instanceId], wrapped the way both native
  /// plugins wrap events, and returns Dart's reply.
  Future<Object?> emit(String method, String? instanceId, [Object? data]) {
    return send(
      method,
      <Object?, Object?>{'instanceId': instanceId, 'data': data},
    );
  }

  /// Sends [method] to Dart with raw [arguments] and returns Dart's reply.
  Future<Object?> send(String method, Object? arguments) async {
    ByteData? reply;

    await _messenger.handlePlatformMessage(
      platform.channel.name,
      _codec.encodeMethodCall(MethodCall(method, arguments)),
      (ByteData? data) => reply = data,
    );

    return reply == null ? null : _codec.decodeEnvelope(reply!);
  }
}
