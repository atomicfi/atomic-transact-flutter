import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';

void main() {
  const MethodChannel channel = MethodChannel('atomic_transact_flutter');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });
}
