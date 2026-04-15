import 'package:flutter/material.dart';
import '../models/event_log.dart';
import '../theme/atomic_theme.dart';

class EventsScreen extends StatelessWidget {
  final EventLog eventLog;

  const EventsScreen({super.key, required this.eventLog});

  void _showEventDetail(BuildContext context, EventEntry event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: atomicSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  _EventBadge(type: event.type),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(event.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatTime(event.timestamp),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: atomicOnSurfaceVariant,
                ),
              ),
              if (event.body.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(event.body, style: const TextStyle(fontSize: 14)),
              ],
              const SizedBox(height: 16),
              const Text('Raw Callback Data',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: atomicOnSurfaceVariant,
                  )),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: atomicBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  event.rawJson,
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
    final events = eventLog.events;

    return Column(
      children: [
        AppBar(
          title: const Text('Events'),
          actions: [
            IconButton(
              icon: Icon(eventLog.newestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 20),
              onPressed: () => eventLog.toggleSortOrder(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: events.isEmpty ? null : () => eventLog.clear(),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, size: 20),
              onSelected: (value) {
                if (value == 'show_all') {
                  eventLog.showAll();
                } else if (value == 'hide_all') {
                  eventLog.hideAll();
                } else {
                  final type = EventType.values.firstWhere((t) => t.name == value);
                  eventLog.toggleType(type);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'show_all', child: Text('Show All')),
                const PopupMenuItem(value: 'hide_all', child: Text('Hide All')),
                const PopupMenuDivider(),
                ...EventType.values.map((type) => PopupMenuItem(
                      value: type.name,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: type.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(type.label)),
                          if (eventLog.visibleTypes.contains(type))
                            const Icon(Icons.check, size: 16),
                        ],
                      ),
                    )),
              ],
            ),
          ],
        ),
        Expanded(
          child: events.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.layers_outlined, size: 48, color: atomicOnSurfaceVariant),
                      SizedBox(height: 16),
                      Text('No Events Yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text(
                        'Events will appear here when\nTransact fires callbacks',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: atomicOnSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _TimelineRow(
                      event: event,
                      onTap: () => _showEventDetail(context, event),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

String _formatTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}

class _TimelineRow extends StatelessWidget {
  final EventEntry event;
  final VoidCallback onTap;

  const _TimelineRow({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Text(
                    _formatTime(event.timestamp),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: atomicOnSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: event.type.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: event.type.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: event.type.color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EventBadge(type: event.type),
                    const SizedBox(height: 4),
                    Text(event.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    if (event.body.isNotEmpty)
                      Text(event.body,
                          style: const TextStyle(
                            fontSize: 12,
                            color: atomicOnSurfaceVariant,
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventBadge extends StatelessWidget {
  final EventType type;

  const _EventBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        type.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: type.color),
      ),
    );
  }
}
