import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
import 'package:atomic_transact_flutter/platform_interface/atomic_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AtomicTransactDataRequest.fromJson', () {
    test('parses a request payload from the platform channel', () {
      // The standard codec hands Dart `List<Object?>` / `Map<Object?, Object?>`,
      // not the concrete types the model declares.
      final request = AtomicTransactDataRequest.fromJson(<Object?, Object?>{
        'taskId': 'task-1',
        'userId': 'user-1',
        'identifier': 'identifier-1',
        'fields': <Object?>['card', 'identity'],
        'data': <Object?, Object?>{'taskWorkflowId': 'workflow-1'},
      });

      expect(request.taskId, 'task-1');
      expect(request.userId, 'user-1');
      expect(request.identifier, 'identifier-1');
      expect(request.fields, ['card', 'identity']);
      expect(request.data, {'taskWorkflowId': 'workflow-1'});
    });

    test('falls back to empty values when keys are missing', () {
      final request = AtomicTransactDataRequest.fromJson(<Object?, Object?>{});

      expect(request.taskId, '');
      expect(request.userId, '');
      expect(request.identifier, '');
      expect(request.fields, isEmpty);
      expect(request.data, isEmpty);
    });
  });

  group('AtomicTransactDataResponse.toJson', () {
    test('serializes card and identity', () {
      final json = const AtomicTransactDataResponse(
        card: AtomicTransactCardData(
          number: '4111111111111111',
          expiry: '12/30',
          cvv: '123',
          cardType: AtomicTransactCardType.debit,
        ),
        identity: AtomicTransactIdentity(
          firstName: 'Ada',
          lastName: 'Lovelace',
          postalCode: '84043',
          address: '1 Main St',
          address2: 'Apt 2',
          city: 'Lehi',
          state: 'UT',
          phone: '8015551234',
          email: 'ada@example.com',
        ),
      ).toJson();

      expect(json, {
        'card': {
          'number': '4111111111111111',
          'expiry': '12/30',
          'cvv': '123',
          'cardType': 'debit',
        },
        'identity': {
          'firstName': 'Ada',
          'lastName': 'Lovelace',
          'postalCode': '84043',
          'address': '1 Main St',
          'address2': 'Apt 2',
          'city': 'Lehi',
          'state': 'UT',
          'phone': '8015551234',
          'email': 'ada@example.com',
        },
      });
    });

    test('omits unset fields so the native SDKs decode them as null', () {
      final json = const AtomicTransactDataResponse(
        card: AtomicTransactCardData(number: '4111111111111111'),
      ).toJson();

      expect(json, {
        'card': {'number': '4111111111111111'}
      });
    });

    test('is empty when nothing is supplied', () {
      expect(const AtomicTransactDataResponse().toJson(), isEmpty);
    });
  });

  group('onDataRequest round trip', () {
    const codec = StandardMethodCodec();
    late AtomicMethodChannel platform;

    setUp(() {
      platform = AtomicMethodChannel();
    });

    /// Simulates the native side invoking `onDataRequest` and returns whatever
    /// the Dart handler replied with.
    Future<Object?> invokeDataRequest([
      Map<Object?, Object?> request = const <Object?, Object?>{},
    ]) async {
      ByteData? reply;

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        platform.channel.name,
        codec.encodeMethodCall(
          MethodCall('onDataRequest', <Object?, Object?>{'request': request}),
        ),
        (ByteData? data) => reply = data,
      );

      return reply == null ? null : codec.decodeEnvelope(reply!);
    }

    test('replies with the response returned by the handler', () async {
      late AtomicTransactDataRequest received;

      platform.onDataRequest = (request) {
        received = request;
        return const AtomicTransactDataResponse(
          card: AtomicTransactCardData(number: '4111111111111111'),
        );
      };

      final reply = await invokeDataRequest(<Object?, Object?>{
        'fields': <Object?>['card'],
        'identifier': 'identifier-1',
      });

      expect(received.fields, ['card']);
      expect(received.identifier, 'identifier-1');
      expect(reply, {
        'card': {'number': '4111111111111111'}
      });
    });

    test('waits for an asynchronous handler before replying', () async {
      platform.onDataRequest = (request) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const AtomicTransactDataResponse(
          identity: AtomicTransactIdentity(firstName: 'Ada'),
        );
      };

      expect(await invokeDataRequest(), {
        'identity': {'firstName': 'Ada'}
      });
    });

    test('replies with null when the handler returns nothing', () async {
      platform.onDataRequest = (request) => null;

      expect(await invokeDataRequest(), isNull);
    });

    test('replies with null when no handler is registered', () async {
      expect(await invokeDataRequest(), isNull);
    });
  });
}
