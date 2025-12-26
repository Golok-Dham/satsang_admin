import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/users/models/user_model.dart';
import '../services/api_service.dart';

part 'admin_user_provider.g.dart';

/// Admin user profile model for current logged-in admin
class AdminUserProfile {
  const AdminUserProfile({required this.id, required this.email, required this.displayName, required this.role});

  factory AdminUserProfile.fromJson(Map<String, dynamic> json) {
    return AdminUserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['role'] as String? ?? 'USER').toUpperCase(),
        orElse: () => UserRole.user,
      ),
    );
  }

  final int id;
  final String email;
  final String displayName;
  final UserRole role;

  /// Check if user has admin role
  bool get isAdmin => role == UserRole.admin;

  /// Check if user has moderator role
  bool get isModerator => role == UserRole.moderator;

  /// Check if user can delete resources (ADMIN only)
  bool get canDelete => isAdmin;

  /// Check if user can manage users (ADMIN only)
  bool get canManageUsers => isAdmin;

  /// Check if user can publish/unpublish content (ADMIN only)
  bool get canPublishContent => isAdmin;

  /// Check if user can create/update resources (ADMIN or MODERATOR)
  bool get canEdit => isAdmin || isModerator;

  /// Check if user can read resources (ADMIN or MODERATOR)
  bool get canRead => isAdmin || isModerator;
}

/// Provider for the current admin user's profile
/// This fetches the user profile including role from the backend
@riverpod
class AdminUser extends _$AdminUser {
  @override
  Future<AdminUserProfile> build() async {
    final apiService = ref.read(apiServiceProvider);

    final response = await apiService.dio.get<Map<String, dynamic>>('/api/user/profile');

    if (response.data == null) {
      throw Exception('Failed to fetch admin user profile');
    }

    final data = response.data!;
    if (data['success'] != true || data['data'] == null) {
      throw Exception(data['error']?['message'] ?? 'Failed to fetch profile');
    }

    return AdminUserProfile.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Refresh the admin user profile
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Convenience provider for checking if current user can delete resources
@riverpod
bool canDelete(Ref ref) {
  final adminUser = ref.watch(adminUserProvider);
  return adminUser.maybeWhen(data: (user) => user.canDelete, orElse: () => false);
}

/// Convenience provider for checking if current user can manage users
@riverpod
bool canManageUsers(Ref ref) {
  final adminUser = ref.watch(adminUserProvider);
  return adminUser.maybeWhen(data: (user) => user.canManageUsers, orElse: () => false);
}

/// Convenience provider for checking if current user can publish content
@riverpod
bool canPublishContent(Ref ref) {
  final adminUser = ref.watch(adminUserProvider);
  return adminUser.maybeWhen(data: (user) => user.canPublishContent, orElse: () => false);
}

/// Convenience provider for getting the current user's role
@riverpod
UserRole? currentUserRole(Ref ref) {
  final adminUser = ref.watch(adminUserProvider);
  return adminUser.maybeWhen(data: (user) => user.role, orElse: () => null);
}
