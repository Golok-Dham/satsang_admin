import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_provider.dart';

/// Dashboard content widget - displays stats and overview
class DashboardContent extends ConsumerWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back!', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Here\'s what\'s happening with your platform today.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Stats',
                onPressed: () => ref.invalidate(dashboardStatsProvider),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: statsAsync.when(
              data: (stats) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Stats Section
                    Text('Users & Sessions', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _StatCard(
                          title: 'Total Users',
                          value: _formatNumber(stats.totalUsers),
                          icon: Icons.people,
                          color: theme.colorScheme.primary,
                        ),
                        _StatCard(
                          title: 'Active Users',
                          value: _formatNumber(stats.activeUsers),
                          icon: Icons.person_outline,
                          color: theme.colorScheme.secondary,
                        ),
                        _StatCard(
                          title: 'Premium Users',
                          value: _formatNumber(stats.premiumUsers),
                          icon: Icons.star,
                          color: Colors.amber,
                        ),
                        _StatCard(
                          title: 'Active Sessions',
                          value: _formatNumber(stats.activeSessions),
                          icon: Icons.devices,
                          color: theme.colorScheme.tertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Content Stats Section
                    Text('Content', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _StatCard(
                          title: 'Total Content',
                          value: _formatNumber(stats.totalContent),
                          icon: Icons.library_music,
                          color: Colors.deepPurple,
                        ),
                        _StatCard(
                          title: 'Videos',
                          value: _formatNumber(stats.videoCount),
                          icon: Icons.video_library,
                          color: Colors.red,
                        ),
                        _StatCard(
                          title: 'Audio',
                          value: _formatNumber(stats.audioCount),
                          icon: Icons.audiotrack,
                          color: Colors.green,
                        ),
                        _StatCard(
                          title: 'Playlists',
                          value: _formatNumber(stats.totalPlaylists),
                          icon: Icons.playlist_play,
                          color: Colors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Features Stats Section
                    Text('Features', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _StatCard(
                          title: 'Divine Quotes',
                          value: _formatNumber(stats.totalQuotes),
                          icon: Icons.format_quote,
                          color: Colors.indigo,
                        ),
                        _StatCard(
                          title: 'Quizzes',
                          value: _formatNumber(stats.totalQuizzes),
                          icon: Icons.quiz,
                          color: Colors.orange,
                        ),
                        _StatCard(
                          title: 'Sankalp Templates',
                          value: _formatNumber(stats.totalSankalpTemplates),
                          icon: Icons.self_improvement,
                          color: Colors.pink,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(stats.timestamp)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Failed to load stats', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(error.toString(), style: theme.textTheme.bodySmall),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => ref.invalidate(dashboardStatsProvider), child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 200,
      height: 120,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 24, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
