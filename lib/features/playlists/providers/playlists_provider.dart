import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/api_models.dart';
import '../../../core/services/api_service.dart';

part 'playlists_provider.g.dart';

/// Provider for fetching playlists list with pagination and filters
@riverpod
class PlaylistsList extends _$PlaylistsList {
  @override
  Future<PagedResponse<Playlist>> build({
    int page = 0,
    int size = 50,
    String? playlistType,
    String? contentType,
    bool? isFeatured,
    bool? isPublic,
  }) async {
    final dio = ref.read(apiServiceProvider).dio;

    final queryParams = <String, dynamic>{'page': page, 'size': size, 'sortBy': 'createdAt', 'sortDir': 'desc'};

    if (playlistType != null) queryParams['playlistType'] = playlistType;
    if (contentType != null) queryParams['contentType'] = contentType;
    if (isFeatured != null) queryParams['isFeatured'] = isFeatured;
    if (isPublic != null) queryParams['isPublic'] = isPublic;

    try {
      final response = await dio.get<Map<String, dynamic>>('/api/admin/playlists', queryParameters: queryParams);

      final apiResponse = ApiResponse.fromJson(response.data!, (data) {
        if (data is! Map<String, dynamic>) return null;
        return PagedResponse<Playlist>.fromJson(data, (json) => Playlist.fromJson(json as Map<String, dynamic>));
      });

      return apiResponse.data ?? PagedResponse(content: [], totalElements: 0, totalPages: 0, size: size, number: page);
    } catch (e) {
      throw Exception('Failed to load playlists: $e');
    }
  }

  /// Refresh playlists list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(apiServiceProvider).dio;
      final queryParams = <String, dynamic>{'page': 0, 'size': 50, 'sortBy': 'createdAt', 'sortDir': 'desc'};

      final response = await dio.get<Map<String, dynamic>>('/api/admin/playlists', queryParameters: queryParams);

      final apiResponse = ApiResponse.fromJson(response.data!, (data) {
        if (data is! Map<String, dynamic>) return null;
        return PagedResponse<Playlist>.fromJson(data, (json) => Playlist.fromJson(json as Map<String, dynamic>));
      });

      return apiResponse.data ?? PagedResponse(content: [], totalElements: 0, totalPages: 0, size: 50, number: 0);
    });
  }
}

/// Provider for a single playlist by ID
@riverpod
Future<Playlist> playlist(Ref ref, int id) async {
  final dio = ref.read(apiServiceProvider).dio;

  try {
    final response = await dio.get<Map<String, dynamic>>('/api/admin/playlists/$id');

    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => data is Map<String, dynamic> ? Playlist.fromJson(data) : null,
    );

    if (apiResponse.data == null) {
      throw Exception('Playlist not found');
    }

    return apiResponse.data!;
  } catch (e) {
    throw Exception('Failed to load playlist: $e');
  }
}

/// Provider for playlist actions (CRUD operations)
@riverpod
class PlaylistActions extends _$PlaylistActions {
  @override
  FutureOr<void> build() {}

  /// Create a new playlist
  Future<Playlist> createPlaylist({
    required String name,
    String? description,
    bool isPublic = true,
    String contentType = 'VIDEO',
    String playlistType = 'SYSTEM',
  }) async {
    state = const AsyncValue.loading();

    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/admin/playlists',
        queryParameters: {'playlistType': playlistType},
        data: {'name': name, 'description': description, 'isPublic': isPublic, 'contentType': contentType},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? Playlist.fromJson(data) : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to create playlist');
      }

      // Invalidate the playlists list to refresh
      ref.invalidate(playlistsListProvider);

      state = const AsyncValue.data(null);
      return apiResponse.data!;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update an existing playlist
  Future<Playlist> updatePlaylist({required int id, required String name, String? description, bool? isPublic}) async {
    state = const AsyncValue.loading();

    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.put<Map<String, dynamic>>(
        '/api/admin/playlists/$id',
        data: {'name': name, 'description': description, 'isPublic': isPublic},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? Playlist.fromJson(data) : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to update playlist');
      }

      // Invalidate both list and detail providers
      ref.invalidate(playlistsListProvider);
      ref.invalidate(playlistProvider(id));

      state = const AsyncValue.data(null);
      return apiResponse.data!;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Delete a playlist
  Future<void> deletePlaylist(int id) async {
    state = const AsyncValue.loading();

    final dio = ref.read(apiServiceProvider).dio;

    try {
      await dio.delete('/api/admin/playlists/$id');

      // Invalidate the playlists list
      ref.invalidate(playlistsListProvider);

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Toggle featured status
  Future<Playlist> toggleFeatured(int id) async {
    state = const AsyncValue.loading();

    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.put<Map<String, dynamic>>('/api/admin/playlists/$id/toggle-featured');

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? Playlist.fromJson(data) : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to toggle featured status');
      }

      // Invalidate providers
      ref.invalidate(playlistsListProvider);
      ref.invalidate(playlistProvider(id));

      state = const AsyncValue.data(null);
      return apiResponse.data!;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Toggle public status
  Future<Playlist> togglePublic(int id) async {
    state = const AsyncValue.loading();

    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.put<Map<String, dynamic>>('/api/admin/playlists/$id/toggle-public');

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? Playlist.fromJson(data) : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to toggle public status');
      }

      // Invalidate providers
      ref.invalidate(playlistsListProvider);
      ref.invalidate(playlistProvider(id));

      state = const AsyncValue.data(null);
      return apiResponse.data!;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update playlist type
  Future<Playlist> updatePlaylistType(int id, String playlistType) async {
    state = const AsyncValue.loading();

    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.put<Map<String, dynamic>>(
        '/api/admin/playlists/$id/type',
        queryParameters: {'playlistType': playlistType},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? Playlist.fromJson(data) : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to update playlist type');
      }

      // Invalidate providers
      ref.invalidate(playlistsListProvider);
      ref.invalidate(playlistProvider(id));

      state = const AsyncValue.data(null);
      return apiResponse.data!;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
