import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/atomic_theme.dart';

enum EventType {
  interaction('Interaction', eventBlue),
  dataRequest('Data Request', eventIndigo),
  authStatus('Auth Status', eventCyan),
  taskStatus('Task Status', eventMint),
  completion('Completion', eventGreen),
  error('Error', eventRed),
  launch('Launch', eventOrange);

  final String label;
  final Color color;
  const EventType(this.label, this.color);
}

class EventEntry {
  final EventType type;
  final String title;
  final String body;
  final Map<String, dynamic>? rawData;
  final DateTime timestamp;

  EventEntry({
    required this.type,
    required this.title,
    required this.body,
    this.rawData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get rawJson {
    if (rawData == null) return '{}';
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(rawData);
  }
}

class EventLog extends ChangeNotifier {
  final List<EventEntry> _events = [];
  bool _newestFirst = true;
  Set<EventType> _visibleTypes = EventType.values.toSet();

  List<EventEntry> get events {
    final filtered = _events.where((e) => _visibleTypes.contains(e.type)).toList();
    if (_newestFirst) {
      return filtered.reversed.toList();
    }
    return filtered;
  }

  bool get newestFirst => _newestFirst;
  Set<EventType> get visibleTypes => _visibleTypes;

  void add(EventEntry entry) {
    _events.add(entry);
    notifyListeners();
  }

  void clear() {
    _events.clear();
    notifyListeners();
  }

  void toggleSortOrder() {
    _newestFirst = !_newestFirst;
    notifyListeners();
  }

  void toggleType(EventType type) {
    if (_visibleTypes.contains(type)) {
      _visibleTypes = _visibleTypes.difference({type});
    } else {
      _visibleTypes = _visibleTypes.union({type});
    }
    notifyListeners();
  }

  void showAll() {
    _visibleTypes = EventType.values.toSet();
    notifyListeners();
  }

  void hideAll() {
    _visibleTypes = {};
    notifyListeners();
  }
}
