import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_state.dart';
import '../models/event_log.dart';
import '../models/pay_link_account.dart';
import '../services/pay_link_api.dart';
import '../theme/atomic_theme.dart';
import '../widgets/full_width_button.dart';
import '../widgets/public_token_banner.dart';
import '../widgets/section_header.dart';
import '../widgets/toggle_row.dart';

/// Lists the Pay Link actions behind the public token and launches them.
class ActionsScreen extends StatefulWidget {
  final AppState state;
  final EventLog eventLog;
  final VoidCallback onNavigateToSettings;

  const ActionsScreen({
    super.key,
    required this.state,
    required this.eventLog,
    required this.onNavigateToSettings,
  });

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
  AppState get state => widget.state;
  EventLog get eventLog => widget.eventLog;

  bool _fetching = false;
  bool _headless = false;

  /// Null until the first fetch.
  List<PayLinkAccount>? _accounts;

  Future<void> _fetch() async {
    setState(() => _fetching = true);
    try {
      final accounts = await fetchPayLinkAccounts(
        apiPath: state.environment.apiPath,
        publicToken: state.publicToken,
      );
      if (mounted) setState(() => _accounts = accounts);
    } catch (e) {
      // Anything thrown here would otherwise only reach the console.
      _showMessage('Failed to fetch actions: $e');
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _launch(PayLinkAction action) async {
    final launch = Atomic.transact(
      config: state.buildActionConfig(actionId: action.id, headless: _headless),
      environment: state.environment,
      debug: state.debug,
      onInteraction: (interaction) {
        eventLog.add(EventEntry(
          type: EventType.interaction,
          title: interaction.name,
          body: interaction.description ?? '',
          rawData: {
            'name': interaction.name,
            'description': interaction.description,
            'value': interaction.value,
          },
        ));
      },
      onDataRequest: (request) {
        // Null unless the Payment Response toggle on the Pay Link tab is on.
        final response = state.buildDataRequestResponse();
        eventLog.add(EventEntry(
          type: EventType.dataRequest,
          title: 'Data Request',
          body: 'Fields: ${request.fields}',
          rawData: {
            'taskId': request.taskId,
            'fields': request.fields,
            'response': response?.toJson(),
          },
        ));
        return response;
      },
      onAuthStatusUpdate: (authStatus) {
        eventLog.add(EventEntry(
          type: EventType.authStatus,
          title: 'Auth Status',
          body: authStatus.status,
          rawData: {'status': authStatus.status},
        ));
      },
      onTaskStatusUpdate: (taskStatus) {
        final actionType = taskStatus.actionType;
        eventLog.add(EventEntry(
          type: EventType.taskStatus,
          title: 'Task Status',
          body: '${taskStatus.status} (${taskStatus.taskId})'
              '${actionType != null ? ' · action: $actionType' : ''}',
          rawData: {
            'status': taskStatus.status,
            'taskId': taskStatus.taskId,
            'actionType': actionType,
          },
        ));
      },
      onCompletion: (type, response, error) {
        if (type == AtomicTransactCompletionType.error) {
          eventLog.add(EventEntry(
            type: EventType.error,
            title: 'Error',
            body: error?.name ?? 'Unknown error',
            rawData: {'error': error?.name},
          ));
        } else {
          eventLog.add(EventEntry(
            type: EventType.completion,
            title: type.name,
            body: response?.reason ?? '',
            rawData: {
              'type': type.name,
              'reason': response?.reason,
              'taskId': response?.taskId,
            },
          ));
        }
      },
      onCleanup: () {
        eventLog.add(EventEntry(
          type: EventType.cleanup,
          title: 'Cleanup',
          body: 'No more callbacks for ${action.type}',
        ));
      },
    );

    try {
      await launch;
    } on PlatformException catch (e) {
      _showMessage('Failed to launch Transact: ${e.message}');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<Widget> _buildAccounts() {
    final accounts = _accounts;
    if (accounts == null) return const [];
    if (accounts.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'No accounts are linked to this token.',
            style: TextStyle(color: atomicOnSurfaceVariant),
          ),
        ),
      ];
    }

    return [
      for (final account in accounts) ...[
        SectionHeader(account.name),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!account.hasActions)
                const ListTile(
                  title: Text(
                    'No actions',
                    style: TextStyle(color: atomicOnSurfaceVariant),
                  ),
                ),
              for (final action in account.actions) _actionTile(action),
              for (final bill in account.bills) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    '${bill.name} bill',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: atomicOnSurfaceVariant,
                    ),
                  ),
                ),
                for (final action in bill.actions) _actionTile(action),
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: 16),
    ];
  }

  Widget _actionTile(PayLinkAction action) {
    return ListTile(
      title: Text(action.type),
      trailing: const Icon(Icons.play_arrow, color: atomicPurple),
      onTap: () => _launch(action),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(title: const Text('Actions')),
        Expanded(
          child: ListView(
            // The AppBar above already accounts for the status bar.
            padding: EdgeInsets.zero,
            children: [
              PublicTokenBanner(
                publicToken: state.publicToken,
                onNavigateToSettings: widget.onNavigateToSettings,
              ),
              ToggleRow(
                title: 'Headless',
                // Transact still shows UI when the action needs it.
                subtitle: 'Ask Transact to skip its UI when it can',
                value: _headless,
                onChanged: (v) => setState(() => _headless = v),
              ),
              ..._buildAccounts(),
            ],
          ),
        ),
        FullWidthButton(
          text: _fetching ? 'Fetching…' : 'Fetch Actions',
          enabled: state.publicToken.isNotEmpty && !_fetching,
          onPressed: _fetch,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
