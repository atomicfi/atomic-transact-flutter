// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:io' show Platform;

import 'types.dart';

/// Provide colors to customize Transact.
class AtomicTheme {
  /// Accepts valid values for use with the color CSS property. For example: #FF0000 or rgb(255, 0, 0). This property will mostly be applied to buttons.
  final String? brandColor;

  /// Accepts valid values for use with the background-color CSS property. For example: #FF0000 or rgb(255, 0, 0). This property will change the overlay background color. This overlay is mainly only seen when Transact is used on a Desktop.
  final String? overlayColor;

  /// Change the overall theme to be dark mode.
  final bool? dark;

  AtomicTheme({
    this.brandColor,
    this.overlayColor,
    this.dark,
  });

  /// Returns a JSON object representation.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'brandColor': brandColor,
      'overlayColor': overlayColor,
      'dark': dark,
    }..removeWhere((key, value) => value == null);
  }
}

/// Pass in enforced deposit settings. Enforcing deposit settings will eliminate company search results that do not support the distribution settings.
class AtomicDistribution {
  /// Can be total to indicate the remaining balance of their paycheck, fixed to indicate a specific dollar amount, or percent to indicate a percentage of their paycheck.
  final AtomicDistributionType type;

  /// When type is fixed, it indicates a dollar amount to be used for the distribution. When type is percent, it indicates a percentage of a paycheck. This is not required if type is total.
  /// This value cannot be updated by the user unless canUpdate is set to true.
  final num? amount;

  /// The operation to perform when updating the distribution. The default value is create which will add a new distribution. The value of update indicates an update to an existing distribution matched by the routing and account number. The value of delete removes a distribution matched by the routing and account number.
  final String? action;

  /// Allows a user to specify any amount they would like, overwriting the default amount. Defaults to false.
  final bool? canUpdate;

  AtomicDistribution({
    required this.type,
    this.amount,
    this.action,
    this.canUpdate,
  });

  /// Returns a JSON object representation.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'amount': amount,
      'action': action,
      'canUpdate': canUpdate,
    }..removeWhere((key, value) => value == null);
  }
}

/// Deeplink step options
abstract class DeeplinkStep {
  const DeeplinkStep();

  AtomicDeeplinkStep get step;
  String get id => step.name.replaceAll("_", "-");

  /// Deeplink to the company search step
  static const DeeplinkStep searchCompany = _SearchCompanyStep();

  /// Deeplink to the payroll search step
  static const DeeplinkStep searchPayroll = _SearchPayrollStep();

  /// Deeplink to the add card step
  static const DeeplinkStep addCard = _AddCardStep();

  /// Deeplink to the company login step
  static DeeplinkStepLoginCompany loginCompany({
    required String companyId,
    String? connectorId,
    bool? singleSwitch,
  }) =>
      DeeplinkStepLoginCompany(
        companyId: companyId,
        connectorId: connectorId,
        singleSwitch: singleSwitch,
      );

  /// Deeplink to the payroll login step
  static DeeplinkStepLoginPayroll loginPayroll({
    required String connectorId,
    required String companyName,
  }) =>
      DeeplinkStepLoginPayroll(
        connectorId: connectorId,
        companyName: companyName,
      );
}

class _SearchCompanyStep extends DeeplinkStep {
  const _SearchCompanyStep();
  @override
  AtomicDeeplinkStep get step => AtomicDeeplinkStep.search_company;
}

class _SearchPayrollStep extends DeeplinkStep {
  const _SearchPayrollStep();
  @override
  AtomicDeeplinkStep get step => AtomicDeeplinkStep.search_payroll;
}

class _AddCardStep extends DeeplinkStep {
  const _AddCardStep();
  @override
  AtomicDeeplinkStep get step => AtomicDeeplinkStep.add_card;
}

/// Deeplink to the company login step with associated data
class DeeplinkStepLoginCompany extends DeeplinkStep {
  final String companyId;
  final String? connectorId;
  final bool? singleSwitch;

  const DeeplinkStepLoginCompany({
    required this.companyId,
    this.connectorId,
    this.singleSwitch,
  });

  @override
  AtomicDeeplinkStep get step => AtomicDeeplinkStep.login_company;
}

/// Deeplink to the payroll login step with associated data
class DeeplinkStepLoginPayroll extends DeeplinkStep {
  final String connectorId;
  final String companyName;

  const DeeplinkStepLoginPayroll({
    required this.connectorId,
    required this.companyName,
  });

  @override
  AtomicDeeplinkStep get step => AtomicDeeplinkStep.login_payroll;
}

/// Deeplink app options for Payments Hub
abstract class DeeplinkApp {
  const DeeplinkApp();

  String get id;

  /// Deeplink to the Transactions app
  static const DeeplinkApp transactions = _TransactionsApp();

  /// Deeplink to the Orders app
  static const DeeplinkApp orders = _OrdersApp();

  /// Deeplink to the Suggestions app
  static const DeeplinkApp suggestions = _SuggestionsApp();

  /// Deeplink to the Pay Now app
  static DeeplinkAppPayNow payNow({
    required List<String> payments,
    required String accountId,
  }) =>
      DeeplinkAppPayNow(
        payments: payments,
        accountId: accountId,
      );
}

class _TransactionsApp extends DeeplinkApp {
  const _TransactionsApp();
  @override
  String get id => 'transactions';
}

class _OrdersApp extends DeeplinkApp {
  const _OrdersApp();
  @override
  String get id => 'orders';
}

class _SuggestionsApp extends DeeplinkApp {
  const _SuggestionsApp();
  @override
  String get id => 'suggestions';
}

/// Deeplink to the Pay Now app with associated data
class DeeplinkAppPayNow extends DeeplinkApp {
  final List<String> payments;
  final String accountId;

  const DeeplinkAppPayNow({
    required this.payments,
    required this.accountId,
  });

  @override
  String get id => 'pay-now';
}

/// Deeplink users into a specific step or app
class AtomicDeeplink {
  final DeeplinkStep? _step;
  final DeeplinkApp? _app;

  const AtomicDeeplink._({
    DeeplinkStep? step,
    DeeplinkApp? app,
  })  : _step = step,
        _app = app;

  /// Create a deeplink to a specific step
  factory AtomicDeeplink.step(DeeplinkStep step) {
    return AtomicDeeplink._(step: step);
  }

  /// Create a deeplink to a specific app in the Payments Hub
  factory AtomicDeeplink.app(DeeplinkApp app) {
    return AtomicDeeplink._(app: app);
  }

  /// Returns a JSON object representation.
  Map<String, dynamic> toJson() {
    final step = _step;
    final app = _app;

    String? companyId;
    String? connectorId;
    String? companyName;
    bool? singleSwitch;
    List<String>? payments;
    String? accountId;

    if (step is DeeplinkStepLoginCompany) {
      companyId = step.companyId;
      connectorId = step.connectorId;
      singleSwitch = step.singleSwitch;
    } else if (step is DeeplinkStepLoginPayroll) {
      connectorId = step.connectorId;
      companyName = step.companyName;
    }

    if (app is DeeplinkAppPayNow) {
      payments = app.payments;
      accountId = app.accountId;
    }

    return <String, dynamic>{
      'step': step?.id,
      'app': app?.id,
      'companyId': companyId,
      'connectorId': connectorId,
      'companyName': companyName,
      'singleSwitch': singleSwitch,
      'payments': payments,
      'accountId': accountId,
    }..removeWhere((key, value) => value == null);
  }
}

/// Enforce search queries
class AtomicSearch {
  /// Filters companies by a specific tag. Possible values include gig-economy, payroll-provider, and unemployment.
  final List<String>? tags;

  /// Exclude companies by a specific tag. Possible values include gig-economy, payroll-provider, and unemployment.
  final List<String>? excludedTags;

  /// The ID of the rule to apply to the search.
  final String? ruleId;

  AtomicSearch({
    this.tags,
    this.excludedTags,
    this.ruleId,
  });

  /// Returns a JSON object representation.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tags': tags,
      'excludedTags': excludedTags,
      'ruleId': ruleId,
    }..removeWhere((key, value) => value == null);
  }
}

/// Override feature flags found in your Atomic Dashboard settings. This parameter can help run A/B tests on features within Transact.
class AtomicExperiments {
  /// Override the Fractional Deposit feature value set within your Atomic Dashboard settings.
  final bool? fractionalDeposits;

  /// Override the Unemployment Carousel feature value set within your Atomic Dashboard settings.
  final bool? unemploymentCarousel;

  AtomicExperiments({
    this.fractionalDeposits,
    this.unemploymentCarousel,
  });

  /// Returns a JSON object representation.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fractionalDeposits': fractionalDeposits,
      'unemploymentCarousel': unemploymentCarousel,
    }..removeWhere((key, value) => value == null);
  }
}

/// Defines configuration for the tasks you wish to execute as part of the task workflow.
class AtomicTask {
  /// One of deposit, verify, switch, or present.
  @Deprecated('Use operation instead')
  final AtomicProductType? product;

  /// One of deposit, verify, switch, present, or tax.
  final AtomicOperationType? operation;

  /// The action to take on completion of the task. Can be either "continue" or "finish." To execute the next task, use "continue." To finish the task workflow and not execute any of the subsequent tasks, use "finish."
  /// Default value: "continue"
  final String? onComplete;

  /// The action to take on failure of the task. Can be either "continue" or "finish." To execute the next task, use "continue." To finish the task workflow and not execute any of the subsequent tasks, use "finish."
  /// Default value: "continue"
  final String? onFail;

  /// Optionally pass in enforced deposit settings. Enforcing deposit settings will eliminate company search results that do not support the distribution settings.
  final AtomicDistribution? distribution;

  AtomicTask({
    @Deprecated('Use operation instead') this.product,
    this.operation,
    this.onComplete = "continue",
    this.onFail = "continue",
    this.distribution,
  }) : assert(operation != null || product != null,
            'Either operation or product must be provided');

  /// Returns a JSON object representation.
  Map<String, dynamic> toJson() {
    String? operationValue;
    if (operation != null) {
      operationValue = operation!.operationName;
    } else if (product != null) {
      operationValue = product!.productName;
    }

    return <String, dynamic>{
      'operation': operationValue,
      'onComplete': onComplete,
      'onFail': onFail,
      'distribution': distribution?.toJson(),
    }..removeWhere((key, value) => value == null);
  }
}

/// Represents customer information
class Customer {
  /// The name of the customer
  final String name;

  Customer({
    required this.name,
  });

  /// Returns a JSON object representation.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
    };
  }
}

/// Configure for how you interact with the Atomic Transact SDK
class AtomicConfig {
  /// The public token returned during AccessToken creation.
  final String publicToken;

  /// The scope
  final String? scope;

  /// Defines configuration for the tasks you wish to execute as part of the task workflow.
  final List<AtomicTask>? tasks;

  /// The product to initiate. Valid values include deposit, verify, switch, or present.
  final AtomicProductType? product;

  /// The additional product to initiate.
  final AtomicProductType? additionalProduct;

  /// Optionally pass in enforced deposit settings. Enforcing deposit settings will eliminate company search results that do not support the distribution settings.
  final AtomicDistribution? distribution;

  /// The linked account to use
  final String? linkedAccount;

  /// Optionally provide colors to customize Transact.
  final AtomicTheme? theme;

  /// Optionally change the language. Could be either 'en' for English or 'es' for Spanish. Default is 'en', unless the user's current locale is Spanish, then Spanish will be used.
  /// Default value: 'en'
  final String language;

  /// Optionally deeplink into a specific step
  final AtomicDeeplink? deeplink;

  /// Optionally pass data to Transact that will be returned to you in webhook events.
  final Map<String, String>? metadata;

  /// Used to optionally enforce search queries
  final AtomicSearch? search;

  /// Handoff allows views to be handled outside of Transact.
  final List<AtomicTransactHandoff>? handoff;

  /// The platform being used
  final Map<String, String> platform = {
    'version': Platform.operatingSystemVersion,
    'name': Platform.operatingSystem
  };

  /// Used to override feature flags
  final AtomicExperiments? experiments;

  /// Customer information
  final Customer? customer;

  AtomicConfig({
    required this.publicToken,
    this.scope,
    this.tasks,
    @Deprecated("This has been moved to 'tasks'") this.product,
    this.additionalProduct,
    @Deprecated("This has been moved to 'tasks'") this.distribution,
    this.linkedAccount,
    this.theme,
    this.language = 'en',
    this.deeplink,
    this.metadata,
    this.search,
    this.handoff,
    this.experiments,
    this.customer,
  }) : assert(tasks != null || product != null,
            'AtomicConfig requires a valid tasks list or a valid product type');

  /// Returns a JSON object representation.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'publicToken': publicToken,
      'scope': scope,
      'tasks': tasks?.map((e) => e.toJson()).toList(),
      'product': product?.productName,
      'additionalProduct': additionalProduct?.productName,
      'distribution': distribution?.toJson(),
      'linkedAccount': linkedAccount,
      'theme': theme?.toJson(),
      'language': language,
      'platform': platform,
      'deeplink': deeplink?.toJson(),
      'metadata': metadata,
      'search': search?.toJson(),
      'handoff': handoff?.map((e) => e.name.replaceAll("_", "-")).toList(),
      'experiments': experiments?.toJson(),
      'customer': customer?.toJson(),
    }..removeWhere((key, value) => value == null);
  }
}

class TransactEnvironment {
  final String transactPath;
  final String apiPath;

  /// Production environment
  static const TransactEnvironment production = TransactEnvironment._(
      'https://transact.atomicfi.com', 'https://api.atomicfi.com');

  /// Sandbox environment
  static const TransactEnvironment sandbox = TransactEnvironment._(
      'https://transact.atomicfi.com', 'https://sandbox-api.atomicfi.com');

  /// Custom environment with specified path
  static TransactEnvironment custom(String transactPath, String apiPath) =>
      TransactEnvironment._(transactPath, apiPath);

  const TransactEnvironment._(this.transactPath, this.apiPath);
}
