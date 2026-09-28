# Android presentation style — PoC

Branch: `poc/android-presentation-style`

## Why this exists

On iOS, the Atomic Transact SDK exposes `presentationStyle` (default `.formSheet`).
On Android, the AAR always calls `startActivity(TransactActivity)` with a **Fullscreen**
theme and `match_parent` content. The Flutter plugin only forwards `presentationStyleIOS`.

There is **no** Android presentation-style API in upstream Atomic today.

## What this PoC adds

### Dart API (parity with iOS)

```dart
await Atomic.transact(
  config: config,
  presentationStyleIOS: AtomicPresentationStyleIOS.formSheet,
  presentationStyleAndroid: AtomicPresentationStyleAndroid.bottomSheet,
);
```

### Android (approximation — not a real Material BottomSheet)

1. **Manifest merger** — replace the AAR Fullscreen theme with
   `AtomicTransact.BottomSheet` (`Theme.AppCompat.DayNight.Dialog`, no title bar).
2. **`FormSheetWindowApplier`** — on `TransactActivity` create/resume, size the window
   to full width × ~90% height, `Gravity.BOTTOM`, dim behind, clip top corners.

This is a **host/plugin-side workaround**. It does not change how Transact renders
internally.

## What a proper upstream fix would look like

| Ask | Why |
|-----|-----|
| `presentationStyleAndroid: fullScreen \| bottomSheet` in Flutter + native SDK | API parity with iOS |
| Present via `BottomSheetDialogFragment` (or Compose ModalBottomSheet) **inside the host Activity** | True sheet UX (grabber, nested scroll, peek) |
| Avoid requiring a Fullscreen `TransactActivity` for Switch | Hosts cannot wrap a foreign Activity in a BottomSheet |

Until the AAR supports this, any plugin- or app-level approach remains an approximation.

## Try this branch locally

```yaml
dependency_overrides:
  atomic_transact_flutter:
    path: ../atomic-transact-flutter   # this checkout
```

Then call `presentationStyleAndroid: AtomicPresentationStyleAndroid.bottomSheet`.
