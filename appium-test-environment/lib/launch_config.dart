import 'dart:convert';

import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';

/// Keys of the launch parameters the conformance suite sends: intent extras on
/// Android, launch environment variables on iOS. The same contract the native
/// test apps implement.
abstract final class LaunchKeys {
  static const launchId = 'TRANSACT_LAUNCH_ID';
  static const publicToken = 'TRANSACT_PUBLIC_TOKEN';
  static const url = 'TRANSACT_URL';
  static const productType = 'TRANSACT_PRODUCT_TYPE';
  static const scopeType = 'TRANSACT_SCOPE_TYPE';
  static const deeplink = 'TRANSACT_DEEPLINK';
  static const handoff = 'TRANSACT_HANDOFF';
  static const customFlow = 'TRANSACT_CUSTOM_FLOW';
  static const deferredPaymentMethodStrategy =
      'TRANSACT_DEFERRED_PAYMENT_METHOD_STRATEGY';
  static const actionId = 'TRANSACT_ACTION_ID';
}

/// Custom flows the suite asks for with `TRANSACT_CUSTOM_FLOW`.
abstract final class CustomFlows {
  /// Hide Transact as soon as auth status reaches `authenticated`.
  static const dismissOnAuthenticated =
      'DISMISS_ON_AUTH_STATUS_UPDATE_AUTHENTICATED';

  /// Host Transact in a fragment. Native Android only.
  static const fragmentFlow = 'FRAGMENT_FLOW';

  /// Marks the pause/resume spec; the pausing itself arrives as commands.
  static const pauseTransact = 'PAUSE_TRANSACT';
}

/// The API the native iOS test app uses; the suite only chooses Transact's URL.
const apiUrl = 'https://api.atomicfi.com';

/// Why a set of launch parameters can't be launched through the Flutter SDK.
class LaunchError implements Exception {
  const LaunchError(this.code, this.message);

  /// Short identifier, logged as `transact-launch-error:<launch id>:<code>`.
  final String code;
  final String message;

  @override
  String toString() => 'LaunchError($code): $message';
}

/// A Transact launch built from the suite's launch parameters.
class TransactLaunch {
  const TransactLaunch({
    required this.config,
    required this.environment,
    this.launchId,
    this.customFlow,
  });

  final AtomicConfig config;
  final TransactEnvironment environment;

  /// A fresh id per `mobile: startActivity` on Android; absent on iOS.
  final String? launchId;

  /// The requested `TRANSACT_CUSTOM_FLOW`, upper-cased.
  final String? customFlow;

  /// Transact asks the app for the payment method through `onDataRequest`.
  bool get answersDataRequests =>
      config.deferredPaymentMethodStrategy ==
      AtomicDeferredPaymentMethodStrategy.sdk;

  bool get hasHandoff => config.handoff?.isNotEmpty ?? false;

  /// The config as it goes to the SDK, without the public token.
  String describeConfig() => jsonEncode(config.toJson()..remove('publicToken'));
}

/// Builds a launch from the suite's launch parameters, or throws a
/// [LaunchError] naming what the Flutter SDK cannot express.
TransactLaunch buildLaunch(Map<String, String> extras) {
  final publicToken = _value(extras, LaunchKeys.publicToken);
  final url = _value(extras, LaunchKeys.url);
  final productType = _value(extras, LaunchKeys.productType)?.toLowerCase();
  final scopeType = _value(extras, LaunchKeys.scopeType)?.toLowerCase();
  if (publicToken == null ||
      url == null ||
      productType == null ||
      scopeType == null) {
    throw const LaunchError(
      'missing-config',
      'Missing TRANSACT_PUBLIC_TOKEN, TRANSACT_URL, TRANSACT_PRODUCT_TYPE or '
          'TRANSACT_SCOPE_TYPE in the launch parameters.',
    );
  }

  return TransactLaunch(
    config: AtomicConfig(
      publicToken: publicToken,
      scope: _scope(scopeType),
      tasks: [_task(productType, _value(extras, LaunchKeys.actionId))],
      deeplink: _deeplink(_value(extras, LaunchKeys.deeplink)),
      handoff: _handoff(_value(extras, LaunchKeys.handoff)),
      deferredPaymentMethodStrategy: _strategy(
        _value(extras, LaunchKeys.deferredPaymentMethodStrategy),
      ),
    ),
    environment: TransactEnvironment.custom(url, apiUrl),
    launchId: _value(extras, LaunchKeys.launchId),
    customFlow: _value(extras, LaunchKeys.customFlow)?.toUpperCase(),
  );
}

String? _value(Map<String, String> extras, String key) {
  final value = extras[key]?.trim();
  return value == null || value.isEmpty ? null : value;
}

/// A `TRANSACT_ACTION_ID` makes it a Pay Link action task, whatever the
/// product, as in the native test apps.
AtomicTask _task(String productType, String? actionId) {
  if (actionId != null) {
    return AtomicTask.action(actionId: actionId);
  }
  if (productType == AtomicOperationType.action.operationName) {
    throw const LaunchError(
      'missing-action-id',
      'TRANSACT_PRODUCT_TYPE is action but TRANSACT_ACTION_ID is missing.',
    );
  }
  return AtomicTask(operation: _operation(productType));
}

AtomicOperationType _operation(String productType) {
  for (final operation in AtomicOperationType.values) {
    if (operation.operationName == productType) {
      return operation;
    }
  }
  throw LaunchError(
    'unsupported-product',
    'The Flutter SDK has no operation for TRANSACT_PRODUCT_TYPE '
        '"$productType".',
  );
}

/// The Flutter config takes the scope as a string; the suite sends
/// `user-link`/`pay-link`, and the native apps also accept underscores.
String _scope(String scopeType) => scopeType.replaceAll('_', '-');

/// `TRANSACT_DEEPLINK` is base64-encoded JSON such as
/// `{"step":"login-company","companyId":"..."}`.
AtomicDeeplink? _deeplink(String? encoded) {
  if (encoded == null) {
    return null;
  }

  final Map<String, dynamic> json;
  try {
    json =
        jsonDecode(utf8.decode(base64.decode(encoded))) as Map<String, dynamic>;
  } on FormatException catch (error) {
    throw LaunchError(
      'invalid-deeplink',
      'TRANSACT_DEEPLINK is not base64-encoded JSON: ${error.message}',
    );
  }

  final step = json['step'] as String?;
  final app = json['app'] as String?;
  if (step != null && app != null) {
    throw LaunchError(
      'unsupported-deeplink',
      'AtomicDeeplink takes a step or an app, not both (step "$step", '
          'app "$app").',
    );
  }
  if (step != null) {
    return AtomicDeeplink.step(_deeplinkStep(step, json));
  }
  if (app != null) {
    return AtomicDeeplink.app(_deeplinkApp(app, json));
  }
  return null;
}

DeeplinkStep _deeplinkStep(String step, Map<String, dynamic> json) {
  switch (step) {
    case 'search-company':
      return DeeplinkStep.searchCompany;
    case 'search-payroll':
      return DeeplinkStep.searchPayroll;
    case 'add-card':
      return DeeplinkStep.addCard;
    case 'account':
      return DeeplinkStep.account(accountId: _required(json, 'accountId'));
    case 'login-company':
      return DeeplinkStep.loginCompany(
        companyId: _required(json, 'companyId'),
        connectorId: json['connectorId'] as String?,
        singleSwitch: json['singleSwitch'] as bool?,
      );
    case 'login-payroll':
      return DeeplinkStep.loginPayroll(
        connectorId: _required(json, 'connectorId'),
        companyName: _required(json, 'companyName'),
      );
    default:
      throw LaunchError(
        'unsupported-deeplink',
        'The Flutter SDK has no deeplink step "$step".',
      );
  }
}

DeeplinkApp _deeplinkApp(String app, Map<String, dynamic> json) {
  switch (app) {
    case 'expenses':
      return DeeplinkApp.expenses;
    case 'orders':
      return DeeplinkApp.orders;
    case 'suggestions':
      return DeeplinkApp.suggestions;
    case 'pay-now':
      return DeeplinkApp.payNow(
        payments: [
          for (final payment in json['payments'] as List<dynamic>? ?? const [])
            '$payment',
        ],
        accountId: _required(json, 'accountId'),
      );
    default:
      throw LaunchError(
        'unsupported-deeplink',
        'The Flutter SDK has no deeplink app "$app".',
      );
  }
}

String _required(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw LaunchError('invalid-deeplink', 'TRANSACT_DEEPLINK is missing "$key".');
}

/// `TRANSACT_HANDOFF` is a comma-separated list such as
/// `authentication-success`.
List<AtomicTransactHandoff>? _handoff(String? value) {
  if (value == null) {
    return null;
  }
  final byName = AtomicTransactHandoff.values.asNameMap();
  return [
    for (final name in value.split(',').map((name) => name.trim()))
      if (name.isNotEmpty)
        byName[name.replaceAll('-', '_')] ??
            (throw LaunchError(
              'unsupported-handoff',
              'The Flutter SDK has no handoff "$name".',
            )),
  ];
}

AtomicDeferredPaymentMethodStrategy? _strategy(String? value) {
  if (value == null) {
    return null;
  }
  return AtomicDeferredPaymentMethodStrategy.values.asNameMap()[value
          .toLowerCase()] ??
      (throw LaunchError(
        'unsupported-strategy',
        'The Flutter SDK has no deferred payment method strategy "$value".',
      ));
}
