import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_user_provider.dart';

/// A widget that conditionally shows its child based on role permissions
///
/// Example usage:
/// ```dart
/// RoleGuard(
///   requiredPermission: Permission.delete,
///   child: IconButton(
///     icon: Icon(Icons.delete),
///     onPressed: _handleDelete,
///   ),
/// )
/// ```
class RoleGuard extends ConsumerWidget {
  const RoleGuard({required this.requiredPermission, required this.child, this.fallback, super.key});

  /// The permission required to show the child
  final Permission requiredPermission;

  /// The widget to show if the user has the required permission
  final Widget child;

  /// Optional fallback widget to show if permission is denied
  /// If null, nothing is rendered
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminUser = ref.watch(adminUserProvider);

    return adminUser.when(
      data: (user) {
        final hasPermission = switch (requiredPermission) {
          Permission.delete => user.canDelete,
          Permission.manageUsers => user.canManageUsers,
          Permission.publishContent => user.canPublishContent,
          Permission.edit => user.canEdit,
          Permission.read => user.canRead,
        };

        if (hasPermission) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
      loading: () => fallback ?? const SizedBox.shrink(),
      error: (_, __) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Permissions that can be checked for role-based access control
enum Permission {
  /// Can delete resources (ADMIN only)
  delete,

  /// Can manage users (ADMIN only)
  manageUsers,

  /// Can publish/unpublish content (ADMIN only)
  publishContent,

  /// Can create/update resources (ADMIN or MODERATOR)
  edit,

  /// Can read resources (ADMIN or MODERATOR)
  read,
}

/// Extension to add role-based visibility to any widget
extension RoleGuardExtension on Widget {
  /// Wrap this widget in a RoleGuard that requires the given permission
  Widget guardedBy(Permission permission, {Widget? fallback}) {
    return RoleGuard(requiredPermission: permission, fallback: fallback, child: this);
  }

  /// Only show this widget to users who can delete (ADMIN only)
  Widget adminOnly({Widget? fallback}) {
    return guardedBy(Permission.delete, fallback: fallback);
  }
}

/// A button that is disabled (instead of hidden) when permission is denied
class RoleAwareButton extends ConsumerWidget {
  const RoleAwareButton({
    required this.requiredPermission,
    required this.onPressed,
    required this.child,
    this.disabledTooltip = 'You do not have permission for this action',
    super.key,
  });

  final Permission requiredPermission;
  final VoidCallback? onPressed;
  final Widget child;
  final String disabledTooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminUser = ref.watch(adminUserProvider);

    return adminUser.when(
      data: (user) {
        final hasPermission = switch (requiredPermission) {
          Permission.delete => user.canDelete,
          Permission.manageUsers => user.canManageUsers,
          Permission.publishContent => user.canPublishContent,
          Permission.edit => user.canEdit,
          Permission.read => user.canRead,
        };

        if (hasPermission) {
          return ElevatedButton(onPressed: onPressed, child: child);
        }

        return Tooltip(
          message: disabledTooltip,
          child: ElevatedButton(onPressed: null, child: child),
        );
      },
      loading: () => ElevatedButton(onPressed: null, child: child),
      error: (_, __) => ElevatedButton(onPressed: null, child: child),
    );
  }
}

/// A helper class for programmatic role checks
class RoleHelper {
  const RoleHelper._();

  /// Check if the admin user has a specific permission
  static bool hasPermission(WidgetRef ref, Permission permission) {
    final adminUser = ref.read(adminUserProvider);
    return adminUser.maybeWhen(
      data: (user) => switch (permission) {
        Permission.delete => user.canDelete,
        Permission.manageUsers => user.canManageUsers,
        Permission.publishContent => user.canPublishContent,
        Permission.edit => user.canEdit,
        Permission.read => user.canRead,
      },
      orElse: () => false,
    );
  }

  /// Check if current user can delete resources
  static bool canDelete(WidgetRef ref) => hasPermission(ref, Permission.delete);

  /// Check if current user can manage users
  static bool canManageUsers(WidgetRef ref) => hasPermission(ref, Permission.manageUsers);

  /// Check if current user can publish content
  static bool canPublishContent(WidgetRef ref) => hasPermission(ref, Permission.publishContent);

  /// Check if current user can edit resources
  static bool canEdit(WidgetRef ref) => hasPermission(ref, Permission.edit);
}
