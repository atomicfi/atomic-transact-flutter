import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:atomic_transact_flutter/atomic_transact_flutter.dart';
import '../data/company_data.dart';
import '../models/app_state.dart';
import '../models/event_log.dart';
import '../theme/atomic_theme.dart';
import '../widgets/full_width_button.dart';
import 'company_login_screen.dart';
import '../widgets/public_token_banner.dart';
import '../widgets/select_grid.dart';

class PayLinkScreen extends StatelessWidget {
  final AppState state;
  final EventLog eventLog;
  final VoidCallback onNavigateToSettings;

  const PayLinkScreen({
    super.key,
    required this.state,
    required this.eventLog,
    required this.onNavigateToSettings,
  });

  void _onInitialize() {
    final config = state.buildPayLinkConfig();

    Atomic.transact(
      config: config,
      environment: state.environment,
      onInteraction: (interaction) {
        eventLog.add(EventEntry(
          type: EventType.interaction,
          title: interaction.name,
          body: interaction.description ?? 'No description',
          rawData: {
            'name': interaction.name,
            'description': interaction.description,
            'value': interaction.value,
            'language': interaction.language,
            'company': interaction.company,
            'product': interaction.product,
          },
        ));
      },
      onDataRequest: (request) {
        eventLog.add(EventEntry(
          type: EventType.dataRequest,
          title: 'Data Request',
          body: 'Fields: ${request.fields}',
          rawData: {
            'fields': request.fields,
            'data': request.data,
          },
        ));
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
        eventLog.add(EventEntry(
          type: EventType.taskStatus,
          title: 'Task Status',
          body: '${taskStatus.status} (${taskStatus.taskId})',
          rawData: {
            'status': taskStatus.status,
            'taskId': taskStatus.taskId,
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
              'handoff': response?.handoff,
            },
          ));
        }
      },
    );
  }

  void _showConfigPreview(BuildContext context) {
    final config = state.buildPayLinkConfig();
    final json = const JsonEncoder.withIndent('  ').convert(config.toJson());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: atomicSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Config Preview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: atomicBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  json,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: atomicOnBackground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Pay Link'),
          actions: [
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: () => _showConfigPreview(context),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PublicTokenBanner(
                  publicToken: state.publicToken,
                  onNavigateToSettings: onNavigateToSettings,
                ),
                SingleSelectGrid<PayLinkTask>(
                  title: 'Task',
                  options: PayLinkTask.values,
                  selected: state.payLinkTask,
                  labelOf: (t) => t.label,
                  onSelect: (t) => state.payLinkTask = t,
                ),
                const SizedBox(height: 8),
                SingleSelectGrid<StartingScreen>(
                  title: 'Starting Screen',
                  options: StartingScreen.values,
                  selected: state.payLinkStartingScreen,
                  labelOf: (s) => s.label,
                  onSelect: (s) => state.payLinkStartingScreen = s,
                ),
                if (state.payLinkStartingScreen == StartingScreen.companyLogin)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CompanyLoginScreen(
                            companies: payLinkSuggestions,
                            onSelectCompany: (id, name) =>
                                state.setPayLinkCompany(id, name),
                          ),
                        ));
                      },
                      child: Text(
                        state.payLinkCompanyName.isNotEmpty
                            ? 'Company: ${state.payLinkCompanyName}'
                            : 'Select Company',
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        FullWidthButton(
          text: 'Initialize',
          enabled: state.publicToken.isNotEmpty,
          onPressed: _onInitialize,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
