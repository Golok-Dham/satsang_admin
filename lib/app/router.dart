import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_content.dart';
import '../features/quotes/presentation/quotes_list_screen.dart';
import '../features/content/presentation/content_list_screen.dart';
import '../features/content/presentation/content_translations_screen.dart';
import '../features/content/presentation/content_lyrics_screen.dart';
import '../features/users/presentation/users_list_screen.dart';
import '../features/categories/presentation/categories_list_screen.dart';
import '../features/playlists/presentation/playlists_list_screen.dart';
import '../features/playlists/presentation/playlist_items_screen.dart';
import '../features/sankalpas/presentation/sankalpas_list_screen.dart';
import '../features/quizzes/presentation/quizzes_list_screen.dart';
import '../features/quizzes/presentation/quiz_form_screen.dart';
import '../features/content/providers/content_provider.dart';
import '../core/providers/auth_provider.dart';
import 'admin_shell.dart';

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

      // Admin shell with persistent sidebar navigation
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/', name: 'dashboard', builder: (context, state) => const DashboardContent()),
          GoRoute(path: '/quotes', name: 'quotes', builder: (context, state) => const QuotesListScreen()),
          GoRoute(path: '/content', name: 'content', builder: (context, state) => const ContentListScreen()),
          GoRoute(path: '/users', name: 'users', builder: (context, state) => const UsersListScreen()),
          GoRoute(path: '/categories', name: 'categories', builder: (context, state) => const CategoriesListScreen()),
          GoRoute(path: '/playlists', name: 'playlists', builder: (context, state) => const PlaylistsListScreen()),

          // Playlist items management
          GoRoute(
            path: '/playlists/:id/items',
            name: 'playlist-items',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              final name = state.uri.queryParameters['name'] ?? 'Playlist';
              final contentType = state.uri.queryParameters['contentType'] ?? 'VIDEO';
              return PlaylistItemsScreen(playlistId: id, playlistName: name, contentType: contentType);
            },
          ),

          GoRoute(path: '/sankalpas', name: 'sankalpas', builder: (context, state) => const SankalpasListScreen()),
          GoRoute(path: '/quizzes', name: 'quizzes', builder: (context, state) => const QuizzesListScreen()),
          GoRoute(path: '/quizzes/new', name: 'quiz-new', builder: (context, state) => const QuizFormScreen()),
          GoRoute(
            path: '/quizzes/:id',
            name: 'quiz-edit',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return QuizFormScreen(quizId: id);
            },
          ),

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

          // Analytics placeholder
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const Center(child: Text('Analytics - Coming Soon')),
          ),
        ],
      ),
    ],
  );
}
