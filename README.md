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


*More info at [https://docs.atomicfi.com](https://docs.atomicfi.com).*