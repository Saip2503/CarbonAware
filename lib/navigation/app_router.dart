import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/dashboard/views/dashboard_screen.dart';
import '../features/logging/views/quick_log_screen.dart';
import '../features/insights/views/insights_panel.dart';

// Shell layout wrapping dashboard, logging, and insights tabs
class ShellNavigationWidget extends StatefulWidget {
  final Widget child;

  const ShellNavigationWidget({super.key, required this.child});

  @override
  State<ShellNavigationWidget> createState() => _ShellNavigationWidgetState();
}

class _ShellNavigationWidgetState extends State<ShellNavigationWidget> {
  int _selectedIndex = 0;

  void _onItemTapped(int index, BuildContext context) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/log');
        break;
      case 2:
        context.go('/insights');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine selected index from path
    final GoRouterState state = GoRouterState.of(context);
    final String path = state.uri.path;
    if (path == '/dashboard') {
      _selectedIndex = 0;
    } else if (path == '/log') {
      _selectedIndex = 1;
    } else if (path == '/insights') {
      _selectedIndex = 2;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            label: 'Quick Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}

// Global navigator key
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to authState changes to refresh router redirect
  final authStateAsync = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (BuildContext context, GoRouterState state) {
      final user = authStateAsync.value;
      final isLoggingIn = state.uri.path == '/login';
      final isRegistering = state.uri.path == '/register';

      // If user is null, they must go to login or register
      if (user == null) {
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      // If user is logged in, redirect them away from login/register to dashboard
      if (isLoggingIn || isRegistering) {
        return '/dashboard';
      }

      return null;
    },
    // Refresh the router when authState updates
    refreshListenable: _GoRouterRefreshStream(ref.read(authRepositoryProvider).authStateChanges),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ShellNavigationWidget(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/log',
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: QuickLogScreen(),
            ),
          ),
          GoRoute(
            path: '/insights',
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: InsightsPanel(),
            ),
          ),
        ],
      ),
    ],
  );
});

// Helper class to convert stream to listenable for GoRouter refresh
class _GoRouterRefreshStream extends ChangeNotifier {
  late final List<dynamic> _subscriptions;

  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscriptions = [
      stream.asBroadcastStream().listen((_) => notifyListeners()),
    ];
  }
}
