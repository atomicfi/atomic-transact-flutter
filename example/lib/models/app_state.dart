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

  // Data request response — returned from onDataRequest when Transact asks the
  // app for card or identity data (deferred payment method strategy).
  String _cardNumber = '';
  String get cardNumber => _cardNumber;
  set cardNumber(String v) { _cardNumber = v; notifyListeners(); }

  String _cardExpiry = '';
  String get cardExpiry => _cardExpiry;
  set cardExpiry(String v) { _cardExpiry = v; notifyListeners(); }

  String _cardCvv = '';
  String get cardCvv => _cardCvv;
  set cardCvv(String v) { _cardCvv = v; notifyListeners(); }

  AtomicTransactCardType? _cardType;
  AtomicTransactCardType? get cardType => _cardType;
  set cardType(AtomicTransactCardType? v) { _cardType = v; notifyListeners(); }

  String _identityFirstName = '';
  String get identityFirstName => _identityFirstName;
  set identityFirstName(String v) { _identityFirstName = v; notifyListeners(); }

  String _identityLastName = '';
  String get identityLastName => _identityLastName;
  set identityLastName(String v) { _identityLastName = v; notifyListeners(); }

  String _identityAddress = '';
  String get identityAddress => _identityAddress;
  set identityAddress(String v) { _identityAddress = v; notifyListeners(); }

  String _identityCity = '';
  String get identityCity => _identityCity;
  set identityCity(String v) { _identityCity = v; notifyListeners(); }

  String _identityState = '';
  String get identityState => _identityState;
  set identityState(String v) { _identityState = v; notifyListeners(); }

  String _identityPostalCode = '';
  String get identityPostalCode => _identityPostalCode;
  set identityPostalCode(String v) { _identityPostalCode = v; notifyListeners(); }

  String _identityPhone = '';
  String get identityPhone => _identityPhone;
  set identityPhone(String v) { _identityPhone = v; notifyListeners(); }

  String _identityEmail = '';
  String get identityEmail => _identityEmail;
  set identityEmail(String v) { _identityEmail = v; notifyListeners(); }

  void clearDataRequestResponse() {
    _cardNumber = '';
    _cardExpiry = '';
    _cardCvv = '';
    _cardType = null;
    _identityFirstName = '';
    _identityLastName = '';
    _identityAddress = '';
    _identityCity = '';
    _identityState = '';
    _identityPostalCode = '';
    _identityPhone = '';
    _identityEmail = '';
    notifyListeners();
  }

  /// Builds the response handed back to Transact from `onDataRequest`, or null
  /// when nothing has been filled in — in which case Transact keeps waiting.
  AtomicTransactDataResponse? buildDataRequestResponse() {
    final card = _cardNumber.isEmpty
        ? null
        : AtomicTransactCardData(
            number: _cardNumber,
            expiry: _cardExpiry.isEmpty ? null : _cardExpiry,
            cvv: _cardCvv.isEmpty ? null : _cardCvv,
            cardType: _cardType,
          );

    final identity = AtomicTransactIdentity(
      firstName: _identityFirstName.isEmpty ? null : _identityFirstName,
      lastName: _identityLastName.isEmpty ? null : _identityLastName,
      address: _identityAddress.isEmpty ? null : _identityAddress,
      city: _identityCity.isEmpty ? null : _identityCity,
      state: _identityState.isEmpty ? null : _identityState,
      postalCode: _identityPostalCode.isEmpty ? null : _identityPostalCode,
      phone: _identityPhone.isEmpty ? null : _identityPhone,
      email: _identityEmail.isEmpty ? null : _identityEmail,
    );

    final hasIdentity = identity.toJson().isNotEmpty;

    if (card == null && !hasIdentity) {
      return null;
    }

    return AtomicTransactDataResponse(
      card: card,
      identity: hasIdentity ? identity : null,
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
