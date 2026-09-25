import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'harness.dart';
import 'transact_controller.dart';

/// Appium test environment for the Atomic Transact Flutter SDK.
///
/// The conformance suite starts this app with `TRANSACT_*` launch parameters
/// and it presents Transact with them straight away, as the native test apps
/// do. The suite never taps this app's own UI.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The iOS pause spec reads PauseStatus from the accessibility tree. The
  // engine turns semantics on in the simulator anyway; this keeps it on
  // wherever the app runs.
  SemanticsBinding.instance.ensureSemantics();
  runApp(const HarnessApp());
}

class HarnessApp extends StatefulWidget {
  const HarnessApp({super.key});

  @override
  State<HarnessApp> createState() => _HarnessAppState();
}

class _HarnessAppState extends State<HarnessApp> with WidgetsBindingObserver {
  final _harness = Harness();
  late final _controller = TransactController(_harness, isIOS: Platform.isIOS);
  final _subscriptions = <StreamSubscription<Object>>[];
  var _started = false;

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(_harness.launches.listen(_controller.launch))
      ..add(_harness.commands.listen(_controller.handleCommand));
    WidgetsBinding.instance.addObserver(this);
    // Transact is presented from the app's own screen, so wait until it is on
    // screen and the app is in the foreground.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startIfResumed());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startIfResumed();
    }
  }

  void _startIfResumed() {
    final state = WidgetsBinding.instance.lifecycleState;
    if (_started || (state != null && state != AppLifecycleState.resumed)) {
      return;
    }
    _started = true;
    unawaited(_start());
  }

  Future<void> _start() async {
    final extras = await _harness.getLaunchExtras();
    if (extras.isEmpty) {
      unawaited(
        _harness.log('No TRANSACT_* launch parameters; nothing to launch'),
      );
      return;
    }
    await _controller.launch(extras);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppiumTestEnvironment',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValueListenableBuilder(
                  valueListenable: _controller.pauseStatus,
                  // Absent rather than empty while there is no result: an
                  // empty node with the identifier is still found by
                  // `~PauseStatus`.
                  builder: (context, pauseStatus, _) => pauseStatus.isEmpty
                      ? const SizedBox.shrink()
                      : Semantics(
                          container: true,
                          identifier: 'PauseStatus',
                          child: Text(pauseStatus, textAlign: TextAlign.center),
                        ),
                ),
                const Spacer(),
                Text(
                  'AppiumTestEnvironment',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder(
                  valueListenable: _controller.status,
                  builder: (context, status, _) =>
                      Text(status, textAlign: TextAlign.center),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
