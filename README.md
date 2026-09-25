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
await Atomic.transact(
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

## Running more than one Transact flow

Every `Atomic.transact` call gets its own callbacks, so launching Transact again
never replaces the callbacks of a flow that's still running. A task can keep
sending `onTaskStatusUpdate` after `onCompletion`, while its work finishes in
the background. `onCleanup` is the last callback a flow sends. After it, the
flow sends nothing more.

```dart
final task = await Atomic.transact(
  config: config,
  onTaskStatusUpdate: (update) => print('${update.taskId}: ${update.status}'),
  onCompletion: (type, response, error) => print('UI closed: ${type.name}'),
  onCleanup: () => print('done'),
);

// Stop receiving this flow's callbacks without closing Transact.
task.remove();
```

`Atomic.close()` closes every flow that hasn't finished or closed yet,
including hidden and paused ones. Those flows get `onCleanup` but not
`onCompletion`, so reset any "Transact is open" state there too.
`Atomic.hide()` hides every Transact on screen, and those flows keep running.

### Upgrading

- `Atomic.transact` no longer ignores calls while Transact is open. Every call
  launches Transact, so disable your launch button until `onCompletion` if you
  only want one flow at a time.
- `Atomic.transact` now returns a `Future<AtomicTransactTask>` instead of
  `Future<void>`. It throws a `PlatformException` if Transact can't be
  presented, so await it or catch the error.

*More info at [https://docs.atomicfi.com](https://docs.atomicfi.com).*