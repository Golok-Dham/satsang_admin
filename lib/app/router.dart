import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/quotes/presentation/quotes_list_screen.dart';
import '../features/content/presentation/content_list_screen.dart';
import '../features/content/presentation/content_translations_screen.dart';
import '../features/content/presentation/content_lyrics_screen.dart';
import '../features/users/presentation/users_list_screen.dart';
import '../features/categories/presentation/categories_list_screen.dart';
import '../features/playlists/presentation/playlists_list_screen.dart';
import '../features/content/providers/content_provider.dart';
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
      GoRoute(path: '/content', name: 'content', builder: (context, state) => const ContentListScreen()),
      GoRoute(path: '/users', name: 'users', builder: (context, state) => const UsersListScreen()),
      GoRoute(path: '/categories', name: 'categories', builder: (context, state) => const CategoriesListScreen()),
      GoRoute(path: '/playlists', name: 'playlists', builder: (context, state) => const PlaylistsListScreen()),

      // Content translations route with deep linking
      GoRoute(
        path: '/content/:id/translations',
        name: 'content-translations',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return Consumer(
            builder: (context, ref, _) {
              final contentAsync = ref.watch(contentItemProvider(id));

              return contentAsync.when(
                data: (content) => ContentTranslationsScreen(content: content),
                loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
                error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
              );
            },
          );
        },
      ),

      // Content lyrics route with deep linking
      GoRoute(
        path: '/content/:id/lyrics',
        name: 'content-lyrics',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          // Need to use Consumer to watch the provider
          return Consumer(
            builder: (context, ref, _) {
              final contentAsync = ref.watch(contentItemProvider(id));

              return contentAsync.when(
                data: (content) => ContentLyricsScreen(content: content),
                loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
                error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
              );
            },
          );
        },
      ),

      // TODO: Add more routes for users, categories, etc.
    ],
  );
}
