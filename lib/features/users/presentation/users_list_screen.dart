import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../core/utils/admin_grid_config.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../models/user_model.dart' as model;
import '../providers/user_provider.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  TrinaGridStateManager? _stateManager;
  List<TrinaRow> _rows = [];

  @override
  void dispose() {
    _searchController.dispose();
    _stateManager?.dispose();
    super.dispose();
  }

  /// Convert UserItem to TrinaRow
  TrinaRow _userToRow(model.UserItem user) {
    return TrinaRow(
      cells: {
        'id': TrinaCell(value: user.id),
        'displayName': TrinaCell(value: user.displayName),
        'email': TrinaCell(value: user.email),
        'phoneNumber': TrinaCell(value: user.phoneNumber ?? ''),
        'status': TrinaCell(value: user.status.name),
        'subscriptionType': TrinaCell(value: user.subscriptionType.name),
        'role': TrinaCell(value: user.role.name),
        'isVerified': TrinaCell(value: user.isVerified),
        'lastLoginTime': TrinaCell(value: user.lastLoginTime),
        'createdAt': TrinaCell(value: user.createdAt),
        'actions': TrinaCell(value: user.id),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(usersListProvider);

    final body = Column(
      children: [
        // Search and Filters
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search users',
                    hintText: 'Search by email, name, phone...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        // Users list with TrinaGrid
        Expanded(
          child: usersAsync.when(
            data: (paginatedUsers) {
              final users = paginatedUsers.content;
              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No users found', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Users will appear here once they register',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Convert users to rows
              _rows = users.map(_userToRow).toList();

              return TrinaGrid(
                columns: [
                  TrinaColumn(
                    title: 'ID',
                    field: 'id',
                    type: TrinaColumnType.number(),
                    width: 80,
                    frozen: TrinaColumnFrozen.start,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Name',
                    field: 'displayName',
                    type: TrinaColumnType.text(),
                    width: 200,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Email',
                    field: 'email',
                    type: TrinaColumnType.text(),
                    width: 250,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Phone',
                    field: 'phoneNumber',
                    type: TrinaColumnType.text(),
                    width: 150,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Status',
                    field: 'status',
                    type: TrinaColumnType.text(),
                    width: 120,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final statusStr = rendererContext.cell.value?.toString() ?? '';
                      final status = model.UserStatus.values.firstWhere(
                        (e) => e.name == statusStr,
                        orElse: () => model.UserStatus.active,
                      );
                      return _buildStatusChip(status);
                    },
                  ),
                  TrinaColumn(
                    title: 'Subscription',
                    field: 'subscriptionType',
                    type: TrinaColumnType.text(),
                    width: 150,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final subStr = rendererContext.cell.value?.toString() ?? '';
                      final subscription = model.SubscriptionType.values.firstWhere(
                        (e) => e.name == subStr,
                        orElse: () => model.SubscriptionType.free,
                      );
                      return _buildSubscriptionChip(subscription);
                    },
                  ),
                  TrinaColumn(
                    title: 'Role',
                    field: 'role',
                    type: TrinaColumnType.text(),
                    width: 120,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final roleStr = rendererContext.cell.value?.toString() ?? '';
                      final role = model.UserRole.values.firstWhere(
                        (e) => e.name == roleStr,
                        orElse: () => model.UserRole.user,
                      );
                      return _buildRoleChip(role);
                    },
                  ),
                  TrinaColumn(
                    title: 'Verified',
                    field: 'isVerified',
                    type: TrinaColumnType.text(),
                    width: 100,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final isVerified = rendererContext.cell.value as bool? ?? false;
                      return Icon(
                        isVerified ? Icons.verified : Icons.pending,
                        color: isVerified ? Colors.green : Colors.orange,
                        size: 20,
                      );
                    },
                  ),
                  TrinaColumn(
                    title: 'Last Login',
                    field: 'lastLoginTime',
                    type: TrinaColumnType.date(),
                    width: 160,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final value = rendererContext.cell.value;
                      final date = value is DateTime ? value : null;
                      return Text(_formatDateTime(date));
                    },
                  ),
                  TrinaColumn(
                    title: 'Created',
                    field: 'createdAt',
                    type: TrinaColumnType.date(),
                    width: 160,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final value = rendererContext.cell.value;
                      final date = value is DateTime ? value : null;
                      return Text(_formatDateTime(date));
                    },
                  ),
                  TrinaColumn(
                    title: 'Actions',
                    field: 'actions',
                    type: TrinaColumnType.text(),
                    width: 100,
                    frozen: TrinaColumnFrozen.end,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final userId = rendererContext.cell.value as int;
                      final user = users.firstWhere((u) => u.id == userId);
                      return _buildActionsMenu(user);
                    },
                  ),
                ],
                rows: _rows,
                onLoaded: (TrinaGridOnLoadedEvent event) {
                  _stateManager = event.stateManager;
                },
                configuration: AdminGridConfig.getConfiguration(context),
                createFooter: (stateManager) {
                  return _buildPagination(paginatedUsers, theme);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.read(usersListProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(usersListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildStatusChip(model.UserStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case model.UserStatus.active:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case model.UserStatus.suspended:
        color = Colors.red;
        icon = Icons.block;
        break;
      case model.UserStatus.inactive:
        color = Colors.grey;
        icon = Icons.pause_circle;
        break;
    }

    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(status.name.toUpperCase()),
      labelStyle: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
    );
  }

  Widget _buildSubscriptionChip(model.SubscriptionType subscription) {
    Color color;
    IconData icon;

    switch (subscription) {
      case model.SubscriptionType.free:
        color = Colors.grey;
        icon = Icons.person;
        break;
      case model.SubscriptionType.premium:
        color = Colors.blue;
        icon = Icons.stars;
        break;
      case model.SubscriptionType.premiumPlus:
        color = Colors.amber;
        icon = Icons.workspace_premium;
        break;
    }

    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(subscription.name.toUpperCase()),
      labelStyle: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
    );
  }

  Widget _buildRoleChip(model.UserRole role) {
    Color color;

    switch (role) {
      case model.UserRole.admin:
        color = Colors.purple;
        break;
      case model.UserRole.moderator:
        color = Colors.orange;
        break;
      case model.UserRole.user:
        color = Colors.grey;
        break;
    }

    return Chip(
      label: Text(role.name.toUpperCase()),
      labelStyle: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
    );
  }

  Widget _buildActionsMenu(model.UserItem user) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _handleAction(value, user),
      itemBuilder: (context) => [
        if (user.status == model.UserStatus.active) const PopupMenuItem(value: 'suspend', child: Text('Suspend User')),
        if (user.status != model.UserStatus.active)
          const PopupMenuItem(value: 'activate', child: Text('Activate User')),
        if (!user.isVerified) const PopupMenuItem(value: 'verify', child: Text('Manually Verify')),
        const PopupMenuItem(value: 'subscription', child: Text('Change Subscription')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'details', child: Text('View Details')),
      ],
    );
  }

  Widget _buildPagination(model.PaginatedUsers paginatedUsers, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Text(
            'Showing ${paginatedUsers.number * paginatedUsers.size + 1}-'
            '${(paginatedUsers.number + 1) * paginatedUsers.size > paginatedUsers.totalElements ? paginatedUsers.totalElements : (paginatedUsers.number + 1) * paginatedUsers.size} '
            'of ${paginatedUsers.totalElements} users',
            style: theme.textTheme.bodyMedium,
          ),
          const Spacer(),
          DropdownButton<int>(
            value: paginatedUsers.size,
            items: const [
              DropdownMenuItem(value: 10, child: Text('10 per page')),
              DropdownMenuItem(value: 20, child: Text('20 per page')),
              DropdownMenuItem(value: 50, child: Text('50 per page')),
              DropdownMenuItem(value: 100, child: Text('100 per page')),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(usersListProvider.notifier).changePageSize(value);
              }
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: paginatedUsers.first
                ? null
                : () => ref.read(usersListProvider.notifier).loadPage(paginatedUsers.number - 1),
          ),
          Text('Page ${paginatedUsers.number + 1} of ${paginatedUsers.totalPages}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: paginatedUsers.last
                ? null
                : () => ref.read(usersListProvider.notifier).loadPage(paginatedUsers.number + 1),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, model.UserItem user) {
    switch (action) {
      case 'suspend':
        _suspendUser(user);
        break;
      case 'activate':
        _activateUser(user);
        break;
      case 'verify':
        _verifyUser(user);
        break;
      case 'subscription':
        _changeSubscription(user);
        break;
      case 'details':
        _viewDetails(user);
        break;
    }
  }

  Future<void> _suspendUser(model.UserItem user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: Text('Are you sure you want to suspend ${user.displayName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Suspend')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(userActionsProvider.notifier).suspendUser(user.id);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'User suspended successfully');
      } catch (e) {
        if (!mounted) return;
        SnackBarHelper.showError(context, 'Failed to suspend user: $e');
      }
    }
  }

  Future<void> _activateUser(model.UserItem user) async {
    try {
      await ref.read(userActionsProvider.notifier).activateUser(user.id);
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'User activated successfully');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to activate user: $e');
    }
  }

  Future<void> _verifyUser(model.UserItem user) async {
    try {
      await ref.read(userActionsProvider.notifier).verifyUser(user.id);
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'User verified successfully');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to verify user: $e');
    }
  }

  Future<void> _changeSubscription(model.UserItem user) async {
    final newSubscription = await showDialog<model.SubscriptionType>(
      context: context,
      builder: (context) => _SubscriptionDialog(currentSubscription: user.subscriptionType),
    );

    if (newSubscription != null && newSubscription != user.subscriptionType) {
      try {
        await ref.read(userActionsProvider.notifier).updateSubscription(user.id, newSubscription);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Subscription updated successfully');
      } catch (e) {
        if (!mounted) return;
        SnackBarHelper.showError(context, 'Failed to update subscription: $e');
      }
    }
  }

  void _viewDetails(model.UserItem user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', '${user.id}'),
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Phone', user.phoneNumber ?? '-'),
              _buildDetailRow('Firebase UID', user.firebaseUid),
              _buildDetailRow('Status', user.status.name.toUpperCase()),
              _buildDetailRow('Subscription', user.subscriptionType.name.toUpperCase()),
              _buildDetailRow('Role', user.role.name.toUpperCase()),
              _buildDetailRow('Language', user.preferredLanguage),
              _buildDetailRow('Max Sessions', '${user.maxConcurrentSessions}'),
              _buildDetailRow('Email Verified', user.isEmailVerified ? 'Yes' : 'No'),
              _buildDetailRow('Phone Verified', user.isPhoneVerified ? 'Yes' : 'No'),
              _buildDetailRow('Last Login', _formatDateTime(user.lastLoginTime)),
              _buildDetailRow('Created', _formatDateTime(user.createdAt)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }
}

/// Stateful dialog for subscription selection
class _SubscriptionDialog extends StatefulWidget {
  const _SubscriptionDialog({required this.currentSubscription});

  final model.SubscriptionType currentSubscription;

  @override
  State<_SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<_SubscriptionDialog> {
  late model.SubscriptionType _selectedSubscription;

  @override
  void initState() {
    super.initState();
    _selectedSubscription = widget.currentSubscription;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Change Subscription'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: model.SubscriptionType.values.map((type) {
          final isSelected = _selectedSubscription == type;
          return Card(
            color: isSelected ? theme.colorScheme.primaryContainer : null,
            child: ListTile(
              title: Text(
                type.name.toUpperCase(),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
                ),
              ),
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
              onTap: () {
                setState(() {
                  _selectedSubscription = type;
                });
              },
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _selectedSubscription), child: const Text('Confirm')),
      ],
    );
  }
}
