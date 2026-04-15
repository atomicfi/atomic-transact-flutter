# atomic_transact_flutter_example

Demonstrates the `atomic_transact_flutter` plugin with a multi-tab UI for testing Pay Link and User Link flows, viewing SDK events, and configuring settings.

## Prerequisites

- Flutter `>=3.41.0` (required for Swift Package Manager support)
- Xcode 16+ (for iOS builds, minimum iOS 15 deployment target)
- Android Studio / JDK 17 (for Android builds)
- For CocoaPods mode: `sudo gem install cocoapods`

Check your setup with `flutter doctor`.

## Running the app

From the `example/` directory:

```sh
flutter pub get

# iOS simulator
flutter run -d iphone

# Android emulator
flutter run -d android

# List available devices
flutter devices
```

## Switching between CocoaPods and Swift Package Manager (iOS)

The example app can use either CocoaPods or Swift Package Manager for iOS. SPM is the default going forward (CocoaPods is being deprecated by Flutter and the iOS community), but both are supported and the plugin's `Package.swift` / podspec work with either.

### Using the toggle script (recommended)

From the repo root:

```sh
./scripts/toggle-example-spm.sh
```

The script detects the current mode (by whether `example/ios/Podfile` exists) and flips to the other. It handles all the cleanup:

- **Switching to SPM**: runs `flutter config --enable-swift-package-manager`, runs `pod deintegrate`, removes `Podfile`/`Podfile.lock`, strips `Pods-Runner.*.xcconfig` includes from `ios/Flutter/Debug.xcconfig` and `Release.xcconfig`, and rewrites `Runner.xcworkspace/contents.xcworkspacedata` to drop the Pods reference.
- **Switching to CocoaPods**: runs `flutter config --no-enable-swift-package-manager`. The next `flutter build ios` regenerates `Podfile` and runs `pod install`.

At the end it runs `flutter build ios --no-codesign` to verify the switch worked.

### Manually

```sh
# Enable SPM
flutter config --enable-swift-package-manager

# Disable SPM (use CocoaPods)
flutter config --no-enable-swift-package-manager
```

If you toggle manually, follow the cleanup steps in the script to avoid stale references.

## Building

```sh
# iOS (release build, no codesign)
flutter build ios --no-codesign

# Android debug APK
flutter build apk --debug

# Android release APK
flutter build apk --release
```

## Ignored files

CocoaPods artifacts (`Podfile`, `Podfile.lock`, `Pods/`) are gitignored in `example/ios/.gitignore` — even if you build in CocoaPods mode locally, those files won't be committed. Commit from SPM mode to keep the Xcode project state clean.
