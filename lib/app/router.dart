import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/quotes/presentation/quotes_list_screen.dart';
import '../core/providers/auth_provider.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on login page, redirect to dashboard
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', name: 'dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/quotes', name: 'quotes', builder: (context, state) => const QuotesListScreen()),
      // TODO: Add more routes for content, users, etc.
    ],
  );
}
