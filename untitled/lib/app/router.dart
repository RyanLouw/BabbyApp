import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/events/presentation/record_event_sheet.dart';
final router = GoRouter(initialLocation: '/login', routes: [
  GoRoute(path: '/login', builder: (_, __) => const AuthScreen()),
  StatefulShellRoute.indexedStack(builder: (_, __, shell) => AppShell(shell: shell), branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
    StatefulShellBranch(routes: [GoRoute(path: '/history', builder: (_, __) => const HistoryScreen())]),
    StatefulShellBranch(routes: [GoRoute(path: '/stats', builder: (_, __) => const StatisticsScreen())]),
    StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen())]),
  ])
]);
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell}); final StatefulNavigationShell shell;
  @override Widget build(context) => Scaffold(body: shell,
    floatingActionButton: FloatingActionButton.extended(onPressed: () => showModalBottomSheet(context: context, showDragHandle: true, builder: (_) => const RecordEventSheet()), icon: const Icon(Icons.add), label: const Text('Record')),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    bottomNavigationBar: NavigationBar(selectedIndex: shell.currentIndex, onDestinationSelected: shell.goBranch, destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.history), label: 'History'),
      NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
      NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
    ]));
}
