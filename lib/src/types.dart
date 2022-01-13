// ignore_for_file: constant_identifier_names

import '../src/events.dart';

/// The product to initiate
enum AtomicProductType {
  /// Update the destination bank account of paychecks
  deposit,

  /// Verify a user’s income and employment status
  verify,

  /// Reduce fraud and onboarding friction with verified profile data from a user’s employer
  identify,
}

/// Type of distribution
enum AtomicDistributionType {
  /// indicate the remaining balance of their paycheck,
  total,

  /// indicate a specific dollar amount
  fixed,

  /// indicate a percentage of their paycheck.
  percent,
}

enum AtomicDeeplinkStep {
  ///
  search_company,

  /// This value requires companyName parameter.
  search_payroll,

  /// This value requires companyId parameter.
  login_company,

  /// This value requires companyName and connectorId.
  login_payroll,
}

///  Transact environment to connect to.
enum AtomicEnvironment {
  /// For any shipping applications
  production,

  /// For development and testing
  sandbox,
}

enum AtomicTransactCompletionType {
  /// Transact finished successfully
  finished,

  /// User manually closed transact
  closed,

  /// Something went wrong connecting to Transact
  error,
}

enum AtomicTransactHandoff {
  /// If the user has reached the login page and decides to exit, they are prompted with a view that asks them to confirm their exit. When exit-prompt is passed into the handoff array, users will no longer be presented with the exit confirmation. The atomic-transact-close event will be triggered in its place. The event will also send the following data: { handoff: 'exit-prompt' }.
  exit_prompt,

  /// When authentication is successful, the user is taken to the success view within Transact. When authentication-success is passed into the handoff array, users will no longer be taken to the success view. The atomic-transact-finish event will be triggered in its place. The event will also send the following data: { handoff: 'authentication-success' }.
  authentication_success,

  /// When authentication takes much longer than expected, the user is taken to the the high latency view within Transact. When high-latency is passed into the handoff array, users will no longer be taken to this view. The atomic-transact-close event will be triggered in its place. The event will also send the following data: { handoff: 'high-latency' }.
  high_latency
}

/// Reasons that transact might fail to load
enum AtomicTransactError {
  /// Likely a network issue
  unableToConnectToTransact,

  /// Issue with encoding the config or a bad URL
  invalidConfig,

  /// Unknown error
  unknownError,
}

/// Closure that will be called when a Transact Interaction event occurs
typedef AtomicInteractionHandler = void Function(
  AtomicTransactInteraction interaction,
);

/// Closure that will be called when a Transact data request event occurs
typedef AtomicDataRequestHandler = void Function(
  AtomicTransactDataRequest request,
);

/// Response with more information when Transact completes and dismisses.
typedef AtomicCompletionHandler = void Function(
  AtomicTransactCompletionType type,
  AtomicTransactResponse? response,
  AtomicTransactError? error,
);
