import 'package:flutter/foundation.dart';
import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';

// Pay Link enums
enum PayLinkTask {
  switchPayment('Payment Switching'),
  present('Bill Manage Present'),
  manage('Bill Manage Bundled UI');

  final String label;
  const PayLinkTask(this.label);
}

enum PayLinkApp {
  payNow('Pay Now'),
  expenses('Expenses'),
  orders('Orders'),
  suggestions('Suggestions');

  final String label;
  const PayLinkApp(this.label);
}

enum StartingScreen {
  welcome('Welcome'),
  search('Search'),
  companyLogin('Company Login'),
  account('Account');

  final String label;
  const StartingScreen(this.label);
}

// User Link enums
enum UserLinkTask {
  deposit('Direct Deposit Switching'),
  verify('Payroll Data'),
  tax('Tax Documents');

  final String label;
  const UserLinkTask(this.label);
}

// URL mode
enum UrlMode { production, sandbox, custom }

class AppState extends ChangeNotifier {
  // Settings
  String _publicToken = '';
  String get publicToken => _publicToken;
  set publicToken(String v) { _publicToken = v; notifyListeners(); }

  UrlMode _urlMode = UrlMode.production;
  UrlMode get urlMode => _urlMode;
  set urlMode(UrlMode v) { _urlMode = v; notifyListeners(); }

  String _customTransactUrl = '';
  String get customTransactUrl => _customTransactUrl;
  set customTransactUrl(String v) { _customTransactUrl = v; notifyListeners(); }

  String _customApiUrl = '';
  String get customApiUrl => _customApiUrl;
  set customApiUrl(String v) { _customApiUrl = v; notifyListeners(); }

  bool _darkMode = true;
  bool get darkMode => _darkMode;
  set darkMode(bool v) { _darkMode = v; notifyListeners(); }

  bool _debug = false;
  bool get debug => _debug;
  set debug(bool v) { _debug = v; notifyListeners(); }

  bool _pauseAfterInit = false;
  bool get pauseAfterInit => _pauseAfterInit;
  set pauseAfterInit(bool v) { _pauseAfterInit = v; notifyListeners(); }

  int _pauseDelaySeconds = 3;
  int get pauseDelaySeconds => _pauseDelaySeconds;
  set pauseDelaySeconds(int v) { _pauseDelaySeconds = v; notifyListeners(); }

  // Payment response — returned from onDataRequest when the SDK deferred
  // payment method strategy is on. Defaults are test values so the round trip
  // works without any typing.
  bool _useSdkPaymentResponse = false;
  bool get useSdkPaymentResponse => _useSdkPaymentResponse;
  set useSdkPaymentResponse(bool v) { _useSdkPaymentResponse = v; notifyListeners(); }

  String _cardNumber = '4242424242424242';
  String get cardNumber => _cardNumber;
  set cardNumber(String v) { _cardNumber = v; notifyListeners(); }

  /// Raw digits as typed, e.g. `0429`. Formatted to `MM/YY` on the way out.
  String _cardExpiry = '0429';
  String get cardExpiry => _cardExpiry;
  set cardExpiry(String v) { _cardExpiry = v; notifyListeners(); }

  String _cardCvv = '123';
  String get cardCvv => _cardCvv;
  set cardCvv(String v) { _cardCvv = v; notifyListeners(); }

  AtomicTransactCardType _cardType = AtomicTransactCardType.credit;
  AtomicTransactCardType get cardType => _cardType;
  set cardType(AtomicTransactCardType v) { _cardType = v; notifyListeners(); }

  String _identityFirstName = 'Jordan';
  String get identityFirstName => _identityFirstName;
  set identityFirstName(String v) { _identityFirstName = v; notifyListeners(); }

  String _identityLastName = 'Rivera';
  String get identityLastName => _identityLastName;
  set identityLastName(String v) { _identityLastName = v; notifyListeners(); }

  String _identityAddress = '1642 Silver Fern Way';
  String get identityAddress => _identityAddress;
  set identityAddress(String v) { _identityAddress = v; notifyListeners(); }

  String _identityAddress2 = 'Apt 4';
  String get identityAddress2 => _identityAddress2;
  set identityAddress2(String v) { _identityAddress2 = v; notifyListeners(); }

  String _identityCity = 'Lehi';
  String get identityCity => _identityCity;
  set identityCity(String v) { _identityCity = v; notifyListeners(); }

  String _identityState = 'UT';
  String get identityState => _identityState;
  set identityState(String v) { _identityState = v; notifyListeners(); }

  String _identityPostalCode = '84043';
  String get identityPostalCode => _identityPostalCode;
  set identityPostalCode(String v) { _identityPostalCode = v; notifyListeners(); }

  String _identityPhone = '8015550118';
  String get identityPhone => _identityPhone;
  set identityPhone(String v) { _identityPhone = v; notifyListeners(); }

  String _identityEmail = 'jordan@example.com';
  String get identityEmail => _identityEmail;
  set identityEmail(String v) { _identityEmail = v; notifyListeners(); }

  bool get hasCardData => _cardNumber.trim().isNotEmpty;

  bool get hasIdentityData => _buildIdentity().toJson().isNotEmpty;

  /// `•••• 4242 · 04/29 · credit`
  String get cardSummary {
    if (!hasCardData) return 'Not set';

    final digits = _cardNumber.replaceAll(RegExp(r'\D'), '');
    final lastFour = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : digits;

    return [
      '•••• $lastFour',
      if (_formattedExpiry != null) _formattedExpiry,
      _cardType.name,
    ].join(' · ');
  }

  /// `Jordan Rivera · Lehi UT 84043`
  String get identitySummary {
    if (!hasIdentityData) return 'Not set';

    final name = [_identityFirstName, _identityLastName]
        .where((p) => p.trim().isNotEmpty)
        .join(' ');
    final place = [_identityCity, _identityState, _identityPostalCode]
        .where((p) => p.trim().isNotEmpty)
        .join(' ');

    return [name, place].where((p) => p.isNotEmpty).join(' · ');
  }

  /// The SDK expects `MM/YY`, so accept bare digits and add the slash.
  String? get _formattedExpiry {
    final digits = _cardExpiry.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 4) {
      return _cardExpiry.trim().isEmpty ? null : _cardExpiry.trim();
    }
    return '${digits.substring(0, 2)}/${digits.substring(2)}';
  }

  String? _orNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  AtomicTransactIdentity _buildIdentity() {
    return AtomicTransactIdentity(
      firstName: _orNull(_identityFirstName),
      lastName: _orNull(_identityLastName),
      address: _orNull(_identityAddress),
      address2: _orNull(_identityAddress2),
      city: _orNull(_identityCity),
      state: _orNull(_identityState),
      postalCode: _orNull(_identityPostalCode),
      phone: _orNull(_identityPhone),
      email: _orNull(_identityEmail),
    );
  }

  /// One-line description of what `onDataRequest` is returning, for logs.
  /// Deliberately reuses the masked summaries — the full card number and CVV
  /// never reach a device log.
  String describeDataRequestResponse(AtomicTransactDataResponse? response) {
    if (response == null) return 'no response sent';

    return [
      if (response.card != null) 'card $cardSummary',
      if (response.identity != null) 'identity $identitySummary',
    ].join(', ');
  }

  /// Built when the SDK strategy is on, so the app answers `onDataRequest`
  /// instead of Transact reading the payment method from the Atomic API.
  /// Null means nothing is sent and Transact keeps waiting.
  AtomicTransactDataResponse? buildDataRequestResponse() {
    if (!_useSdkPaymentResponse) return null;

    final card = hasCardData
        ? AtomicTransactCardData(
            number: _cardNumber.trim(),
            expiry: _formattedExpiry,
            cvv: _orNull(_cardCvv),
            cardType: _cardType,
          )
        : null;

    if (card == null && !hasIdentityData) return null;

    return AtomicTransactDataResponse(
      card: card,
      identity: hasIdentityData ? _buildIdentity() : null,
    );
  }

  // Pay Link
  PayLinkTask _payLinkTask = PayLinkTask.switchPayment;
  PayLinkTask get payLinkTask => _payLinkTask;
  set payLinkTask(PayLinkTask v) { _payLinkTask = v; notifyListeners(); }

  Set<PayLinkApp> _payLinkApps = {};
  Set<PayLinkApp> get payLinkApps => _payLinkApps;
  void togglePayLinkApp(PayLinkApp app) {
    if (_payLinkApps.contains(app)) {
      _payLinkApps = Set.from(_payLinkApps)..remove(app);
    } else {
      _payLinkApps = Set.from(_payLinkApps)..add(app);
    }
    notifyListeners();
  }

  StartingScreen _payLinkStartingScreen = StartingScreen.welcome;
  StartingScreen get payLinkStartingScreen => _payLinkStartingScreen;
  set payLinkStartingScreen(StartingScreen v) { _payLinkStartingScreen = v; notifyListeners(); }

  String _payLinkCompanyId = '';
  String get payLinkCompanyId => _payLinkCompanyId;
  String _payLinkCompanyName = '';
  String get payLinkCompanyName => _payLinkCompanyName;
  void setPayLinkCompany(String id, String name) {
    _payLinkCompanyId = id;
    _payLinkCompanyName = name;
    notifyListeners();
  }

  String _payLinkAccountId = '';
  String get payLinkAccountId => _payLinkAccountId;
  set payLinkAccountId(String v) { _payLinkAccountId = v; notifyListeners(); }

  // User Link
  UserLinkTask _userLinkTask = UserLinkTask.deposit;
  UserLinkTask get userLinkTask => _userLinkTask;
  set userLinkTask(UserLinkTask v) { _userLinkTask = v; notifyListeners(); }

  StartingScreen _userLinkStartingScreen = StartingScreen.welcome;
  StartingScreen get userLinkStartingScreen => _userLinkStartingScreen;
  set userLinkStartingScreen(StartingScreen v) { _userLinkStartingScreen = v; notifyListeners(); }

  String _userLinkCompanyId = '';
  String get userLinkCompanyId => _userLinkCompanyId;
  String _userLinkCompanyName = '';
  String get userLinkCompanyName => _userLinkCompanyName;
  void setUserLinkCompany(String id, String name) {
    _userLinkCompanyId = id;
    _userLinkCompanyName = name;
    notifyListeners();
  }

  // Environment helper
  TransactEnvironment get environment {
    switch (_urlMode) {
      case UrlMode.production:
        return TransactEnvironment.production;
      case UrlMode.sandbox:
        return TransactEnvironment.sandbox;
      case UrlMode.custom:
        return TransactEnvironment.custom(_customTransactUrl, _customApiUrl);
    }
  }

  // Theme helper
  AtomicTheme get theme => AtomicTheme(dark: _darkMode);

  // Pay Link config builder
  AtomicConfig buildPayLinkConfig() {
    AtomicOperationType op;
    switch (_payLinkTask) {
      case PayLinkTask.switchPayment:
        op = AtomicOperationType.switchPayment;
      case PayLinkTask.present:
        op = AtomicOperationType.present;
      case PayLinkTask.manage:
        op = AtomicOperationType.manage;
    }

    List<TaskApp>? apps;
    if (_payLinkTask == PayLinkTask.manage && _payLinkApps.isNotEmpty) {
      apps = _payLinkApps.map((a) {
        switch (a) {
          case PayLinkApp.payNow:
            return TaskApp.payNow;
          case PayLinkApp.expenses:
            return TaskApp.expenses;
          case PayLinkApp.orders:
            return TaskApp.orders;
          case PayLinkApp.suggestions:
            return TaskApp.suggestions;
        }
      }).toList();
    }

    DeeplinkStep? step;
    switch (_payLinkStartingScreen) {
      case StartingScreen.welcome:
        break;
      case StartingScreen.search:
        step = DeeplinkStep.searchCompany;
      case StartingScreen.companyLogin:
        if (_payLinkCompanyId.isNotEmpty) {
          step = DeeplinkStep.loginCompany(companyId: _payLinkCompanyId);
        }
      case StartingScreen.account:
        if (_payLinkAccountId.isNotEmpty) {
          step = DeeplinkStep.account(accountId: _payLinkAccountId);
        }
    }

    return AtomicConfig(
      publicToken: _publicToken,
      scope: 'pay-link',
      tasks: [AtomicTask(operation: op, apps: apps)],
      theme: theme,
      deeplink: step != null ? AtomicDeeplink.step(step) : null,
      // Left unset when off, so Transact falls back to its API default.
      deferredPaymentMethodStrategy: _useSdkPaymentResponse
          ? AtomicDeferredPaymentMethodStrategy.sdk
          : null,
    );
  }

  // Actions config builder
  AtomicConfig buildActionConfig({
    required String actionId,
    required bool headless,
  }) {
    return AtomicConfig(
      publicToken: _publicToken,
      scope: 'pay-link',
      tasks: [AtomicTask.action(actionId: actionId, headless: headless)],
      theme: theme,
      // Same as Pay Link: an action that asks for a payment method gets the
      // Payment Response data through onDataRequest.
      deferredPaymentMethodStrategy: _useSdkPaymentResponse
          ? AtomicDeferredPaymentMethodStrategy.sdk
          : null,
    );
  }

  // User Link config builder
  AtomicConfig buildUserLinkConfig() {
    AtomicOperationType op;
    switch (_userLinkTask) {
      case UserLinkTask.deposit:
        op = AtomicOperationType.deposit;
      case UserLinkTask.verify:
        op = AtomicOperationType.verify;
      case UserLinkTask.tax:
        op = AtomicOperationType.tax;
    }

    DeeplinkStep? step;
    switch (_userLinkStartingScreen) {
      case StartingScreen.welcome:
        break;
      case StartingScreen.search:
        step = DeeplinkStep.searchCompany;
      case StartingScreen.companyLogin:
        if (_userLinkCompanyId.isNotEmpty) {
          step = DeeplinkStep.loginCompany(companyId: _userLinkCompanyId);
        }
      case StartingScreen.account:
        break;
    }

    return AtomicConfig(
      publicToken: _publicToken,
      scope: 'user-link',
      tasks: [AtomicTask(operation: op)],
      theme: theme,
      deeplink: step != null ? AtomicDeeplink.step(step) : null,
    );
  }
}
