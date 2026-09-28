import 'dart:convert';

import 'package:appium_test_environment/launch_config.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, String> extras([Map<String, String> overrides = const {}]) => {
  LaunchKeys.publicToken: 'token-123',
  LaunchKeys.url: 'https://transact.atomicfi.com',
  LaunchKeys.productType: 'deposit',
  LaunchKeys.scopeType: 'user-link',
  ...overrides,
};

String base64Json(Object json) => base64.encode(utf8.encode(jsonEncode(json)));

Matcher throwsLaunchError(String code) =>
    throwsA(isA<LaunchError>().having((error) => error.code, 'code', code));

void main() {
  test('builds the config, environment and ids from the launch parameters', () {
    final launch = buildLaunch(
      extras({
        LaunchKeys.launchId: 'launch-1',
        LaunchKeys.customFlow: 'dismiss_on_auth_status_update_authenticated',
      }),
    );

    expect(launch.config.toJson(), {
      'publicToken': 'token-123',
      'scope': 'user-link',
      'tasks': [
        {
          'operation': 'deposit',
          'onComplete': 'continue',
          'onFail': 'continue',
        },
      ],
      'language': 'en',
    });
    expect(launch.environment.transactPath, 'https://transact.atomicfi.com');
    expect(launch.environment.apiPath, apiUrl);
    expect(launch.launchId, 'launch-1');
    expect(launch.customFlow, CustomFlows.dismissOnAuthenticated);
    expect(launch.answersDataRequests, isFalse);
    expect(launch.hasHandoff, isFalse);
  });

  test('maps the products the suite sends to operations', () {
    String operation(String product) =>
        buildLaunch(extras({LaunchKeys.productType: product})).config
                .toJson()['tasks'][0]['operation']
            as String;

    expect(operation('deposit'), 'deposit');
    expect(operation('VERIFY'), 'verify');
    expect(operation('switch'), 'switch');
  });

  test('accepts underscored scopes, as the native test apps do', () {
    expect(
      buildLaunch(extras({LaunchKeys.scopeType: 'pay_link'})).config.scope,
      'pay-link',
    );
  });

  test('refuses to launch without the required parameters', () {
    for (final key in [
      LaunchKeys.publicToken,
      LaunchKeys.url,
      LaunchKeys.productType,
      LaunchKeys.scopeType,
    ]) {
      expect(
        () => buildLaunch(extras()..remove(key)),
        throwsLaunchError('missing-config'),
        reason: key,
      );
    }
    expect(
      () => buildLaunch(extras({LaunchKeys.publicToken: '  '})),
      throwsLaunchError('missing-config'),
    );
  });

  test('launches a Pay Link action from TRANSACT_ACTION_ID', () {
    final launch = buildLaunch(
      extras({
        LaunchKeys.productType: 'action',
        LaunchKeys.scopeType: 'pay-link',
        LaunchKeys.actionId: 'action-1',
      }),
    );

    expect(launch.config.toJson()['tasks'], [
      {
        'operation': 'action',
        'action': {'id': 'action-1'},
      },
    ]);
  });

  test('refuses an action product without an action id', () {
    expect(
      () => buildLaunch(extras({LaunchKeys.productType: 'action'})),
      throwsLaunchError('missing-action-id'),
    );
  });

  test('reports a product the SDK has no operation for', () {
    expect(
      () => buildLaunch(extras({LaunchKeys.productType: 'identify'})),
      throwsLaunchError('unsupported-product'),
    );
  });

  group('deeplink', () {
    test('decodes a base64 login-company step', () {
      final launch = buildLaunch(
        extras({
          LaunchKeys.deeplink: base64Json({
            'step': 'login-company',
            'companyId': 'company-1',
            'connectorId': 'connector-1',
          }),
        }),
      );

      expect(launch.config.toJson()['deeplink'], {
        'step': 'login-company',
        'companyId': 'company-1',
        'connectorId': 'connector-1',
      });
    });

    test('decodes the other steps and apps', () {
      Map<String, dynamic>? deeplink(Map<String, Object> json) =>
          buildLaunch(extras({LaunchKeys.deeplink: base64Json(json)})).config
                  .toJson()['deeplink']
              as Map<String, dynamic>?;

      expect(deeplink({'step': 'search-company'}), {'step': 'search-company'});
      expect(deeplink({'step': 'add-card'}), {'step': 'add-card'});
      expect(deeplink({'step': 'account', 'accountId': 'account-1'}), {
        'step': 'account',
        'accountId': 'account-1',
      });
      expect(
        deeplink({
          'step': 'login-payroll',
          'connectorId': 'connector-1',
          'companyName': 'Acme',
        }),
        {
          'step': 'login-payroll',
          'connectorId': 'connector-1',
          'companyName': 'Acme',
        },
      );
      expect(
        deeplink({
          'app': 'pay-now',
          'payments': ['payment-1'],
          'accountId': 'account-1',
        }),
        {
          'app': 'pay-now',
          'payments': ['payment-1'],
          'accountId': 'account-1',
        },
      );
    });

    test('rejects what the Flutter deeplink cannot express', () {
      expect(
        () => buildLaunch(extras({LaunchKeys.deeplink: 'not base64!'})),
        throwsLaunchError('invalid-deeplink'),
      );
      expect(
        () => buildLaunch(
          extras({
            LaunchKeys.deeplink: base64Json({'step': 'login-company'}),
          }),
        ),
        throwsLaunchError('invalid-deeplink'),
      );
      expect(
        () => buildLaunch(
          extras({
            LaunchKeys.deeplink: base64Json({'step': 'manual-fallback'}),
          }),
        ),
        throwsLaunchError('unsupported-deeplink'),
      );
      expect(
        () => buildLaunch(
          extras({
            LaunchKeys.deeplink: base64Json({
              'step': 'search-company',
              'app': 'orders',
            }),
          }),
        ),
        throwsLaunchError('unsupported-deeplink'),
      );
    });
  });

  group('handoff', () {
    test('takes a comma-separated list', () {
      final launch = buildLaunch(
        extras({LaunchKeys.handoff: 'authentication-success, exit-prompt'}),
      );

      expect(launch.config.toJson()['handoff'], [
        'authentication-success',
        'exit-prompt',
      ]);
      expect(launch.hasHandoff, isTrue);
    });

    test('rejects a handoff the SDK does not have', () {
      expect(
        () => buildLaunch(extras({LaunchKeys.handoff: 'selected-company'})),
        throwsLaunchError('unsupported-handoff'),
      );
    });
  });

  group('deferred payment method strategy', () {
    test('sdk makes the harness answer data requests', () {
      final launch = buildLaunch(
        extras({LaunchKeys.deferredPaymentMethodStrategy: 'SDK'}),
      );

      expect(launch.config.toJson()['deferredPaymentMethodStrategy'], 'sdk');
      expect(launch.answersDataRequests, isTrue);
    });

    test('api leaves data requests unanswered', () {
      expect(
        buildLaunch(extras({LaunchKeys.deferredPaymentMethodStrategy: 'api'}))
            .answersDataRequests,
        isFalse,
      );
    });

    test('rejects an unknown strategy', () {
      expect(
        () => buildLaunch(
          extras({LaunchKeys.deferredPaymentMethodStrategy: 'sometimes'}),
        ),
        throwsLaunchError('unsupported-strategy'),
      );
    });
  });

  test('describes the config without the public token', () {
    final description = buildLaunch(extras()).describeConfig();

    expect(description, isNot(contains('token-123')));
    expect(jsonDecode(description), containsPair('scope', 'user-link'));
  });
}
