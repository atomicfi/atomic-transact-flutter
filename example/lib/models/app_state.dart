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
  companyLogin('Company Login');

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
