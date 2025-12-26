import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/auth_provider.dart';
import '../core/providers/theme_provider.dart';

/// Admin shell layout with collapsible sidebar navigation
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _selectedIndex = 0;

  /// Whether the sidebar is expanded (showing labels) or collapsed (icons only)
  bool _isExpanded = false;

  /// Sidebar widths
  static const double _collapsedWidth = 72.0;
  static const double _expandedWidth = 250.0;

  static const _navigationItems = [
    _NavItem(path: '/', icon: Icons.dashboard_outlined, label: 'Dashboard'),
    _NavItem(path: '/content', icon: Icons.video_library_outlined, label: 'Content'),
    _NavItem(path: '/categories', icon: Icons.category_outlined, label: 'Categories'),
    _NavItem(path: '/users', icon: Icons.people_outlined, label: 'Users'),
    _NavItem(path: '/playlists', icon: Icons.playlist_play_outlined, label: 'Playlists'),
    _NavItem(path: '/sankalpas', icon: Icons.self_improvement_outlined, label: 'Sankalpas'),
    _NavItem(path: '/quizzes', icon: Icons.quiz_outlined, label: 'Quizzes'),
    _NavItem(path: '/quotes', icon: Icons.format_quote_outlined, label: 'Quotes'),
    _NavItem(path: '/analytics', icon: Icons.analytics_outlined, label: 'Analytics'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navigationItems.length; i++) {
      if (location == _navigationItems[i].path ||
          (location.startsWith(_navigationItems[i].path) && _navigationItems[i].path != '/')) {
        if (_selectedIndex != i) {
          setState(() => _selectedIndex = i);
        }
        return;
      }
    }
  }

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
    context.go(_navigationItems[index].path);
  }

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isWideScreen = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(_navigationItems[_selectedIndex].label),
        leading: isWideScreen
            ? IconButton(
                icon: Icon(_isExpanded ? Icons.menu_open : Icons.menu),
                tooltip: _isExpanded ? 'Collapse menu' : 'Expand menu',
                onPressed: _toggleSidebar,
              )
            : Builder(
                builder: (context) =>
                    IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              context.go(GoRouterState.of(context).matchedLocation);
            },
          ),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          // Theme switcher
          PopupMenuButton<AdminTheme>(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Change theme',
            onSelected: (theme) {
              ref.read(adminThemeProvider.notifier).setTheme(theme);
            },
            itemBuilder: (context) => AdminTheme.values.map((theme) {
              final isSelected = ref.read(adminThemeProvider) == theme;
              return PopupMenuItem<AdminTheme>(
                value: theme,
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(theme.displayName),
                  ],
                ),
              );
            }).toList(),
          ),
          // Dark mode toggle
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: ref.watch(themeModeProvider) == ThemeMode.dark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          const SizedBox(width: 8),
          PopupMenuButton(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(radius: 16, child: Text((user?.email ?? 'A')[0].toUpperCase())),
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
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () async {
                  await ref.read(authServiceProvider.notifier).signOut();
                },
              ),
            ],
          ),
        ],
      ),
      drawer: isWideScreen ? null : _buildDrawer(),
      body: Row(
        children: [
          // Collapsible sidebar for wide screens
          if (isWideScreen) _buildSidebar(),
          // Main content
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final sidebarColor = ref.watch(sidebarColorProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _isExpanded ? _expandedWidth : _collapsedWidth,
      child: Material(
        color: sidebarColor,
        child: Column(
          children: [
            // Logo header
            Container(
              height: 64,
              padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 12),
              child: Row(
                mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings, size: 28, color: Colors.white),
                  if (_isExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Satsang Admin',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            // Navigation items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _navigationItems.length,
                itemBuilder: (context, index) {
                  final item = _navigationItems[index];
                  final isSelected = index == _selectedIndex;

                  return _buildNavItem(item: item, isSelected: isSelected, onTap: () => _onDestinationSelected(index));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required _NavItem item, required bool isSelected, required VoidCallback onTap}) {
    final iconWidget = Icon(item.icon, color: isSelected ? Colors.white : Colors.white70, size: 24);

    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: _isExpanded ? 12 : 8, vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 12 : 0, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isExpanded
              ? Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Center(child: iconWidget),
        ),
      ),
    );

    // Show tooltip only when collapsed
    if (!_isExpanded) {
      return Tooltip(
        message: item.label,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        child: content,
      );
    }

    return content;
  }

  Widget _buildDrawer() {
    final sidebarColor = ref.watch(sidebarColorProvider);

    return Drawer(
      backgroundColor: sidebarColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              height: 80,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, size: 32, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Satsang Admin',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            // Navigation items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _navigationItems.length,
                itemBuilder: (context, index) {
                  final item = _navigationItems[index];
                  final isSelected = index == _selectedIndex;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _onDestinationSelected(index);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon, color: isSelected ? Colors.white : Colors.white70, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.path, required this.icon, required this.label});

  final String path;
  final IconData icon;
  final String label;
}
