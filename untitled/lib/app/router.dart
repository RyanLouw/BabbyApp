import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/ad_banner.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/domain/auth_redirect.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';

final _authRefresh = _AuthRefreshListenable(FirebaseAuth.instance);

final router = GoRouter(
  initialLocation: '/home',
  refreshListenable: _authRefresh,
  redirect: (context, state) => authRedirect(
    signedIn: FirebaseAuth.instance.currentUser != null,
    location: state.matchedLocation,
  ),
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const AuthScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (_, __) => const HistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (_, __) => const StatisticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(FirebaseAuth auth) {
    _subscription = auth.authStateChanges().listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: shell.goBranch,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                label: 'Settings',
              ),
            ],
          ),
          // Keep the ad outside every tab's content and separated from the
          // navigation controls so it never overlays tracking actions.
          const AdBanner(),
        ],
      ),
    );
  }
}
