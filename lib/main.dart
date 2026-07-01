import 'package:flutter/material.dart';

import 'app_state.dart';
import 'pages/history_page.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/stats_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const GymRecordApp());
}

class GymRecordApp extends StatefulWidget {
  const GymRecordApp({super.key});

  @override
  State<GymRecordApp> createState() => _GymRecordAppState();
}

class _GymRecordAppState extends State<GymRecordApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appState.loadData();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      appState: _appState,
      child: MaterialApp(
        title: '健身记录',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const List<Widget> _pages = [
    HomePage(),
    HistoryPage(),
    StatsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '记录',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
