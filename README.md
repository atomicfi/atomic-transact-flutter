# Atomic Transact for Flutter

[![pub](https://img.shields.io/pub/v/atomic_transact_flutter.svg)](https://pub.dev/packages/atomic_transact_flutter)

A Flutter plugin that wraps the native [Atomic Transact SDKs](https://docs.atomicfi.com/reference/transact-sdk)

## Installation

Add `atomic_transact_flutter` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/):

```yaml
dependencies:
  ...
  atomic_transact_flutter: <version>
```

### iOS Requirements

- Xcode 12.0 or greater
- iOS 14.0 or greater

### Android Requirements

Set the `minSdkVersion` in `android/app/build.gradle`:

```groovy
android {
    defaultConfig {
        minSdkVersion 21 // or greater
    }
}
```


## Responding to data requests

Transact emits a data request when it needs information that only your app can
supply, such as card or identity details for a deferred payment method. Return
an `AtomicTransactDataResponse` from `onDataRequest` and it is sent back to
Transact. The handler may be asynchronous, so you can prompt the user or call
your backend before responding.

```dart
Atomic.transact(
  config: config,
  onDataRequest: (request) async {
    // request.fields lists what Transact is asking for, e.g. ['card']
    final card = await promptForCard();

    return AtomicTransactDataResponse(
      card: AtomicTransactCardData(
        number: card.number,
        expiry: card.expiry, // MM/YY
        cvv: card.cvv,
        cardType: AtomicTransactCardType.debit,
      ),
      identity: const AtomicTransactIdentity(
        firstName: 'Ada',
        lastName: 'Lovelace',
        postalCode: '84043',
      ),
    );
  },
);
```

Returning `null` sends nothing back, and Transact keeps waiting for data.

*More info at [https://docs.atomicfi.com](https://docs.atomicfi.com).*