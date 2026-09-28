# AppiumTestEnvironment (Flutter)

The Flutter counterpart to the native Android and iOS Appium test apps. It exists so the shared
conformance suite in `mobile-conformance-tests` can run against the Flutter wrapper: the suite
selects this app and otherwise runs unchanged.

It shows only a status line. The suite launches it with `TRANSACT_*` parameters and it presents
Transact with that configuration straight away, through the plugin's Dart API. The native code here
only moves data between the suite and Dart, so what the suite exercises is the wrapper itself. Every
call to the SDK lives in `lib/transact_controller.dart`.

## The contract

### Android

| What the suite does | How it's satisfied here |
| --- | --- |
| Starts `<applicationId>/.MainActivity` with `TRANSACT_*` string extras | `MainActivity.kt` hands them to Dart; `lib/launch_config.dart` turns them into an `AtomicConfig` |
| Starts it again with a fresh `TRANSACT_LAUNCH_ID` | `singleTask`; a start that reaches the running activity is forwarded from `onNewIntent`, and Dart ignores a launch id it has already launched |
| Broadcasts `PAUSE_TRANSACT` / `RESUME_TRANSACT` to `.TransactCommandReceiver` by explicit component | The manifest-declared receiver hands the command to Dart, which calls `Atomic.pauseTransact()` / `resume()` |
| Looks for its markers (`callback:Launch`, `RECEIVER …`) in logcat | `AppiumHarness.log()` writes them under the `AppiumTestEnvironment` tag. Dart's `print` would land under `flutter`, and `debugPrint` is throttled and shared with the SDK's debug output |
| Finds `//*[@text="AppiumTestEnvironment"]` once Transact is gone | The activity's theme has a native action bar titled with the app label. Flutter's own text only reaches the accessibility tree as `content-desc`, never `text` |
| Attaches to the `WEBVIEW_<applicationId>` context | Transact is launched with `debug: true`, which makes its WebView debuggable |

### iOS

| What the suite does | How it's satisfied here |
| --- | --- |
| Passes `TRANSACT_*` as launch environment variables (`mobile: launchApp`) | `AppiumHarness.swift` reads `ProcessInfo` |
| Opens `atomictest://pause` / `atomictest://resume` in this app (`mobile: deepLink` with the bundle id) | `Info.plist` registers `atomictest`. `AppiumHarness` receives the URL as a scene delegate and hands it to Dart. `FlutterDeepLinkingEnabled` is off so Flutter does not also route it |
| Reads `~PauseStatus` and expects `paused` | A `Semantics(identifier: 'PauseStatus')` text. Flutter's semantics tree is always on in the simulator, and the identifier becomes the accessibility identifier |
| Finds alerts by title (`Task Completed`, `Finished with Handoff: …`, `DISMISS_ON_AUTH_STATUS_UPDATE_AUTHENTICATED`) and taps `RESPOND!` / `Okay` | Native `UIAlertController`s, presented one at a time over whatever is on top, Transact included |
| Looks for its markers in the simulator log | `os_log` at default level with public values; `log stream` leaves out info/debug entries and shows other values as `<private>` |

## Building

```bash
flutter build apk --release             # -> build/app/outputs/flutter-apk/app-release.apk
flutter build ios --simulator --debug   # -> build/ios/iphonesimulator/Runner.app
```

- **iOS is a debug build.** Flutter only builds debug for the simulator, which is fine: the app is
  launched by the suite, not by `flutter run`.
- **Android release builds go through R8**, which Flutter always runs for release. The Transact
  Android SDK references Uplink classes it neither depends on nor tells R8 about, so
  `android/app/proguard-rules.pro` carries the two `-dontwarn` rules R8 generates for them. Any
  Flutter app built for release needs the same.
- **The Android Gradle plugin is pinned to the example app's version (8.11).** The current Flutter
  template's AGP 9 checks each library's `compileSdk` against its dependencies, and the plugin's 35
  fails that check.

## Running the conformance suite against it

```bash
cd mobile-conformance-tests/appium

ANDROID_DEVICE_NAME=emulator-5554 ANDROID_APP_PATH=/path/to/app-release.apk npm run wdio:android:flutter
IOS_UDID=<udid> IOS_PLATFORM_VERSION=<version> IOS_APP_PATH=/path/to/Runner.app npm run wdio:ios:flutter
```

The `:flutter` scripts set `TARGET_APP_KIND=flutter` and this app's identifier
(`com.atomicfi.appiumtestenvironment.flutter` / `com.atomicfi.AppiumTestEnvironment.flutter`), so it
installs alongside the native and React Native test apps. `TARGET_APP_KIND` also skips the specs
covering APIs this wrapper does not expose.

After a rebuild, remove the old app first: iOS runs with `noReset`, and UiAutomator2 skips
reinstalling an APK with the same version code. Either uninstall it or build with
`--build-number=$(date +%s)`.

## CI

`.github/workflows/appium-e2e.yml` runs on every pull request: analyze and test this app, then build
it for both platforms and run the conformance suite on a GitHub-hosted Android emulator and iOS
simulator. The job summary lists every spec as passed, failed, skipped (with its ticket) or not
started.

## Gotchas worth knowing

- **PauseStatus only ever shows the outcome of the last pause.** It is not on screen otherwise, and a
  resume clears it rather than showing `resumed`: the spec pauses twice in one launch and reads the
  status straight away, so nothing earlier may still be showing when it looks.
- **Alerts are queued in the order their callbacks fire.** XCUITest only sees the topmost alert, and
  in the auth-dismiss flow `Task Completed` follows the dismiss alert within a second. The dismiss
  alert also waits for `Atomic.hide()` to finish, so it is not presented on the Transact being hidden.
- **If a failure only happens on Android, rebuild with `--profile`.** It is not minified, which rules
  R8 out.
- **A bare `simctl openurl atomictest://…` can land in another test app**, since they all register
  the scheme. The suite passes this app's bundle id, so its own commands arrive here.
