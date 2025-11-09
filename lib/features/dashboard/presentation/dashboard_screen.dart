import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Satsang Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          PopupMenuButton(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      (user?.email ?? 'A')[0].toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(user?.email ?? 'Admin'),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign Out'),
                ),
                onTap: () async {
                  await ref.read(authServiceProvider.notifier).signOut();
                },
              ),
            ],
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          // TODO: Handle navigation
        },
        children: const [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings, size: 48),
                SizedBox(height: 8),
                Text('Satsang Admin', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.dashboard),
            label: Text('Dashboard'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.video_library),
            label: Text('Content'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.category),
            label: Text('Categories'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.people),
            label: Text('Users'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.playlist_play),
            label: Text('Playlists'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.self_improvement),
            label: Text('Sankalpas'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.format_quote),
            label: Text('Quotes'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.analytics),
            label: Text('Analytics'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Here\'s what\'s happening with your platform today.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _StatsCard(
                    title: 'Total Users',
                    value: '---',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  _StatsCard(
                    title: 'Total Content',
                    value: '---',
                    icon: Icons.video_library,
                    color: Colors.green,
                  ),
                  _StatsCard(
                    title: 'Total Views',
                    value: '---',
                    icon: Icons.visibility,
                    color: Colors.orange,
                  ),
                  _StatsCard(
                    title: 'Active Sessions',
                    value: '---',
                    icon: Icons.play_circle,
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              value,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
