import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/api_service.dart';
import '../models/user_model.dart';

part 'user_provider.g.dart';

/// Provider for paginated users list with server-side filtering/sorting
@riverpod
class UsersList extends _$UsersList {
  int _currentPage = 0;
  int _pageSize = 20;
  String _sortBy = 'createdAt';
  String _sortDir = 'desc';

  @override
  Future<PaginatedUsers> build() async {
    return _fetchUsers();
  }

  Future<PaginatedUsers> _fetchUsers() async {
    final dio = ref.read(apiServiceProvider).dio;

    final response = await dio.get<Map<String, dynamic>>(
      '/api/admin/users',
      queryParameters: {'page': _currentPage, 'size': _pageSize, 'sortBy': _sortBy, 'sortDir': _sortDir},
    );

    if (response.data != null && response.data!['success'] == true) {
      return PaginatedUsers.fromJson(response.data!['data'] as Map<String, dynamic>);
    }

    throw Exception('Failed to load users');
  }

  /// Load specific page
  Future<void> loadPage(int page) async {
    _currentPage = page;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUsers());
  }

  /// Change page size
  Future<void> changePageSize(int size) async {
    _pageSize = size;
    _currentPage = 0; // Reset to first page
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUsers());
  }

  /// Change sorting
  Future<void> changeSorting(String sortBy, String sortDir) async {
    _sortBy = sortBy;
    _sortDir = sortDir;
    _currentPage = 0; // Reset to first page
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUsers());
  }

  /// Refresh current page
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUsers());
  }
}

/// Provider for single user details
@riverpod
class UserDetails extends _$UserDetails {
  @override
  Future<UserItem?> build(int userId) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.get<Map<String, dynamic>>('/api/admin/users/$userId');

      if (response.data != null && response.data!['success'] == true) {
        return UserItem.fromJson(response.data!['data'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Provider for user actions (suspend, activate, etc.)
@riverpod
class UserActions extends _$UserActions {
  @override
  FutureOr<void> build() {
    // No-op build
  }

  /// Suspend a user
  Future<void> suspendUser(int userId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final dio = ref.read(apiServiceProvider).dio;

      await dio.put<Map<String, dynamic>>('/api/admin/users/$userId/suspend');

      // Invalidate users list to trigger refresh
      ref.invalidate(usersListProvider);
    });
  }

  /// Activate a user
  Future<void> activateUser(int userId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final dio = ref.read(apiServiceProvider).dio;

      await dio.put<Map<String, dynamic>>('/api/admin/users/$userId/activate');

      // Invalidate users list to trigger refresh
      ref.invalidate(usersListProvider);
    });
  }

  /// Update user subscription
  Future<void> updateSubscription(int userId, SubscriptionType subscriptionType) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final dio = ref.read(apiServiceProvider).dio;

      await dio.put<Map<String, dynamic>>(
        '/api/admin/users/$userId/subscription',
        queryParameters: {'subscriptionType': subscriptionType.name.toUpperCase()},
      );

      // Invalidate users list to trigger refresh
      ref.invalidate(usersListProvider);
    });
  }

  /// Manually verify a user (email and phone)
  Future<void> verifyUser(int userId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final dio = ref.read(apiServiceProvider).dio;

      await dio.put<Map<String, dynamic>>('/api/admin/users/$userId/verify');

      // Invalidate users list to trigger refresh
      ref.invalidate(usersListProvider);
    });
  }
}
