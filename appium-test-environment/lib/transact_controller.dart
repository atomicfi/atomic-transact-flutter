import 'dart:async';
import 'dart:convert';

import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'harness.dart';
import 'launch_config.dart';

/// Launches Transact from the suite's launch parameters and mirrors every
/// callback into the platform log in the native test app's wording, so the
/// suite's log assertions match unchanged. The only file that calls the SDK.
class TransactController {
  TransactController(this._harness, {required this.isIOS});

  final Harness _harness;
  final bool isIOS;

  /// Read by the iOS pause spec as `~PauseStatus`, which expects `paused`.
  /// Empty (and so absent from the screen) except for the outcome of the last
  /// pause, or a failed resume: the spec pauses again later in the same launch
  /// and reads this straight away, so no earlier value may still be showing.
  final pauseStatus = ValueNotifier<String>('');

  /// A line for whoever is watching the screen.
  final status = ValueNotifier<String>('Waiting for launch parameters');

  String? _lastLaunchId;
  PausedTransactRef? _paused;
  Future<void> _commands = Future.value();
  Future<void> _alerts = Future.value();

  /// The native iOS test app's canned answer to a data request.
  static const dataResponse = AtomicTransactDataResponse(
    card: AtomicTransactCardData(
      number: '4111222233334444',
      expiry: '12/29',
      cvv: '444',
    ),
    identity: AtomicTransactIdentity(
      firstName: 'first',
      lastName: 'last',
      postalCode: '12345',
      address: 'somewhere',
      address2: '',
      city: 'someplace',
      state: 'UT',
    ),
  );

  void _log(String message) => unawaited(_harness.log(message));

  /// Launches Transact for one set of launch parameters.
  Future<void> launch(Map<String, String> extras) async {
    final launchId = extras[LaunchKeys.launchId];
    if (launchId != null && launchId == _lastLaunchId) {
      _log('Ignoring duplicate launch: $launchId');
      return;
    }
    _lastLaunchId = launchId;
    final logId = launchId ?? 'no-launch-id';
    _log('Launch parameters: ${extras.keys.join(', ')}');

    final TransactLaunch launch;
    try {
      launch = buildLaunch(extras);
    } on LaunchError catch (error) {
      _log('transact-launch-error:$logId:${error.code}');
      _log(error.message);
      status.value = error.message;
      return;
    }

    final customFlow = launch.customFlow;
    if (customFlow != null) {
      _log('Custom flow requested: $customFlow');
      if (customFlow == CustomFlows.fragmentFlow) {
        _log(
          'Custom flow FRAGMENT_FLOW is not supported: the Flutter SDK '
          'presents Transact itself and exposes no fragment host.',
        );
      }
    }
    _log('Config: ${launch.describeConfig()}');

    try {
      final task = await Atomic.transact(
        config: launch.config,
        environment: launch.environment,
        // Makes the Transact WebView debuggable, which is what gives Appium a
        // WEBVIEW context on Android.
        debug: true,
        onLaunch: () {
          _log('RECEIVER launch');
          _log('callback:Launch');
        },
        onInteraction: (interaction) {
          _log(
            'RECEIVER interaction ${interaction.name} '
            '${_json(interaction.value)}',
          );
          _log('callback:Interaction');
        },
        onAuthStatusUpdate: (update) => _onAuthStatus(launch, update),
        onTaskStatusUpdate: (update) => _onTaskStatus(launch, update),
        onDataRequest: (request) => _onDataRequest(launch, request),
        onCompletion: _onCompletion,
        onCleanup: () => _log('callback:Cleanup'),
      );
      _log('transact-launch:$logId');
      _log('Transact instance: ${task.instanceId}');
      status.value = 'Transact launched';
    } catch (error) {
      _log('transact-launch-error:$logId:${_code(error)}');
      _log('Atomic.transact failed: $error');
      status.value = 'Atomic.transact failed: $error';
    }
  }

  void _onAuthStatus(
    TransactLaunch launch,
    AtomicTransactAuthStatusUpdate update,
  ) {
    // The plugin reports statuses in lower case; the native test app logs the
    // SDK's enum names, which is what the specs match.
    final authStatus = update.status.toUpperCase();
    _log('RECEIVER auth status updated $authStatus');

    if (authStatus == 'AUTHENTICATED' &&
        launch.customFlow == CustomFlows.dismissOnAuthenticated) {
      _log('Hiding Transact on AUTHENTICATED');
      final hidden = Atomic.hide().catchError((Object error) {
        _log('Atomic.hide failed: $error');
      });
      if (isIOS) {
        // Queued now so it stays ahead of the Task Completed alert that
        // follows; presented once Transact is out of the way.
        unawaited(
          _queueAlert(CustomFlows.dismissOnAuthenticated, after: hidden),
        );
      } else {
        unawaited(hidden);
      }
    }
  }

  void _onTaskStatus(
    TransactLaunch launch,
    AtomicTransactTaskStatusUpdate update,
  ) {
    final taskStatus = update.status.toUpperCase();
    _log('RECEIVER task status updated $taskStatus');

    // As in the native iOS test app: a handoff flow ends in its own alert.
    if (isIOS && taskStatus == 'COMPLETED' && !launch.hasHandoff) {
      unawaited(
        _queueAlert(
          'Task Completed',
          message: 'company: ${update.company.name}',
        ),
      );
    }
  }

  Future<AtomicTransactDataResponse?> _onDataRequest(
    TransactLaunch launch,
    AtomicTransactDataRequest request,
  ) async {
    if (!launch.answersDataRequests) {
      return null;
    }
    _log('RECEIVER data request ${request.fields}');

    // The native iOS test app answers only once RESPOND! is tapped, which is
    // what the iOS spec does. Android has no alert to tap.
    if (isIOS) {
      await _queueAlert('Received Data Request', button: 'RESPOND!');
    }

    _log('Sent data response');
    return dataResponse;
  }

  void _onCompletion(
    AtomicTransactCompletionType type,
    AtomicTransactResponse? response,
    AtomicTransactError? error,
  ) {
    switch (type) {
      case AtomicTransactCompletionType.finished:
        _log('RECEIVER finish ${_describeResponse(response)}');
        final handoff = response?.handoff;
        if (handoff != null && handoff.isNotEmpty) {
          _log('Finished with Handoff: $handoff');
          if (isIOS) {
            unawaited(_queueAlert('Finished with Handoff: $handoff'));
          }
        }
      case AtomicTransactCompletionType.closed:
        _log('RECEIVER close ${_describeResponse(response)}');
      case AtomicTransactCompletionType.error:
        _log('RECEIVER error ${error?.name}');
    }
    _log('callback:Completion');
  }

  /// Carries out a command from the suite. Commands run one at a time, in the
  /// order they arrived.
  Future<void> handleCommand(HarnessCommand command) {
    final next = _commands.then((_) => _runCommand(command));
    _commands = next.catchError((Object _) {});
    return next;
  }

  Future<void> _runCommand(HarnessCommand command) async {
    _log('RECEIVER command ${command.name}');
    switch (command.name.toUpperCase()) {
      case 'PAUSE_TRANSACT' || 'PAUSE':
        await _pause();
      case 'RESUME_TRANSACT' || 'RESUME':
        await _resume();
      default:
        _log(
          'Command ${command.name} is not supported by the Flutter test app',
        );
    }
  }

  Future<void> _pause() async {
    pauseStatus.value = '';
    _log('RECEIVER: Pausing transact');
    try {
      _paused = await Atomic.pauseTransact();
      _log('Transact paused');
      pauseStatus.value = 'paused';
    } catch (error) {
      _log('Error pausing transact: $error');
      pauseStatus.value = 'pause-error';
    }
  }

  Future<void> _resume() async {
    pauseStatus.value = '';
    _log('RECEIVER: Resuming transact');
    final paused = _paused;
    if (paused == null) {
      _log('No paused Transact to resume');
      pauseStatus.value = 'resume-error';
      return;
    }
    try {
      await paused.resume();
      _paused = null;
      _log('Transact resumed');
    } catch (error) {
      _log('Error resuming transact: $error');
      pauseStatus.value = 'resume-error';
    }
  }

  /// Shows alerts one at a time, in the order they were queued: XCUITest only
  /// sees the topmost alert, and the specs find each one by title. Completes
  /// when this alert's button is tapped.
  Future<void> _queueAlert(
    String title, {
    String? message,
    String button = 'Okay',
    Future<void>? after,
  }) {
    final shown = _alerts.then((_) async {
      if (after != null) {
        await after;
      }
      _log('Presenting alert: $title');
      await _harness.showAlert(title, message: message, button: button);
      _log('Alert acknowledged: $title');
    });
    _alerts = shown.catchError((Object error) {
      _log('Alert failed: $title: $error');
    });
    return _alerts;
  }

  static String _describeResponse(AtomicTransactResponse? response) {
    if (response == null) {
      return 'null';
    }
    return _json({
      if (response.taskId != null) 'taskId': response.taskId,
      if (response.handoff != null) 'handoff': response.handoff,
      if (response.reason != null) 'reason': response.reason,
      if (response.data.isNotEmpty) 'data': response.data,
    });
  }

  static String _json(Object? value) =>
      jsonEncode(value, toEncodable: (Object? unknown) => '$unknown');

  static String _code(Object error) =>
      error is PlatformException ? error.code : '${error.runtimeType}';
}
