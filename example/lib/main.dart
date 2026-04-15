import 'package:flutter/material.dart';
import 'models/app_state.dart';
import 'models/event_log.dart';
import 'screens/events_screen.dart';
import 'screens/pay_link_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_link_screen.dart';
import 'theme/atomic_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appState = AppState();
  final _eventLog = EventLog();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChanged);
    _eventLog.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    _eventLog.removeListener(_onStateChanged);
    _appState.dispose();
    _eventLog.dispose();
    super.dispose();
  }

  void _onStateChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atomic Transact Flutter',
      theme: buildAtomicTheme(),
      debugShowCheckedModeBanner: false,
      home: _MainScreen(appState: _appState, eventLog: _eventLog),
    );
  }
}

class _MainScreen extends StatefulWidget {
  final AppState appState;
  final EventLog eventLog;

  const _MainScreen({required this.appState, required this.eventLog});

  @override
  State<_MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<_MainScreen> {
  int _selectedIndex = 0;

  void _navigateToSettings() {
    setState(() => _selectedIndex = 3);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      PayLinkScreen(
        state: widget.appState,
        eventLog: widget.eventLog,
        onNavigateToSettings: _navigateToSettings,
      ),
      UserLinkScreen(
        state: widget.appState,
        eventLog: widget.eventLog,
        onNavigateToSettings: _navigateToSettings,
      ),
      EventsScreen(eventLog: widget.eventLog),
      SettingsScreen(state: widget.appState),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.payment),
            label: 'Pay Link',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user),
            label: 'User Link',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
