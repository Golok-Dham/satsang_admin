import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/api_models.dart';
import '../../../core/services/api_service.dart';
import '../models/content_model.dart';

part 'content_provider.g.dart';

/// Provider for fetching content list with pagination
@riverpod
class ContentList extends _$ContentList {
  @override
  Future<PagedResponse<ContentItem>> build({
    int page = 0,
    int size = 50,
    String lang = 'en',
    String? contentType,
    String? status,
    String? search,
  }) async {
    final dio = ref.read(apiServiceProvider).dio;

    final queryParams = <String, dynamic>{'page': page, 'size': size, 'lang': lang};

    if (contentType != null) queryParams['contentType'] = contentType;
    if (status != null) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    try {
      final response = await dio.get<Map<String, dynamic>>('/api/admin/content', queryParameters: queryParams);

      final apiResponse = ApiResponse.fromJson(response.data!, (data) {
        if (data is! Map<String, dynamic>) return null;
        return PagedResponse<ContentItem>.fromJson(data, (json) => ContentItem.fromJson(json as Map<String, dynamic>));
      });

      return apiResponse.data ?? PagedResponse(content: [], totalElements: 0, totalPages: 0, size: size, number: page);
    } catch (e) {
      throw Exception('Failed to load content: $e');
    }
  }

  /// Refresh content list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(apiServiceProvider).dio;
      final queryParams = <String, dynamic>{'page': 0, 'size': 50, 'lang': 'en'};

      final response = await dio.get<Map<String, dynamic>>('/api/admin/content', queryParameters: queryParams);
      final apiResponse = ApiResponse.fromJson(response.data!, (data) {
        if (data is! Map<String, dynamic>) return null;
        return PagedResponse<ContentItem>.fromJson(data, (json) => ContentItem.fromJson(json as Map<String, dynamic>));
      });
      return apiResponse.data ?? PagedResponse(content: [], totalElements: 0, totalPages: 0, size: 50, number: 0);
    });
  }
}

/// Provider for a single content item by ID
@riverpod
Future<ContentItem> contentItem(Ref ref, int id) async {
  final dio = ref.read(apiServiceProvider).dio;

  try {
    final response = await dio.get<Map<String, dynamic>>('/api/admin/content/$id');

    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => data is Map<String, dynamic> ? ContentItem.fromJson(data) : null,
    );

    if (apiResponse.data == null) {
      throw Exception('Content not found');
    }

    return apiResponse.data!;
  } catch (e) {
    throw Exception('Failed to load content: $e');
  }
}

/// Provider for content actions (create, update, delete)
@riverpod
class ContentActions extends _$ContentActions {
  @override
  void build() {}

  /// Create new content
  Future<ContentItem> createContent(ContentItem content) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.post<Map<String, dynamic>>('/api/admin/content', data: content.toJson());

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? ContentItem.fromJson(data) : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to create content');
      }

      // Refresh content list
      ref.invalidate(contentListProvider);

      return apiResponse.data!;
    } catch (e) {
      throw Exception('Failed to create content: $e');
    }
  }

  /// Update existing content
  Future<ContentItem> updateContent(int id, ContentItem content) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.put<Map<String, dynamic>>('/api/admin/content/$id', data: content.toJson());

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? ContentItem.fromJson(data) : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to update content');
      }

      // Invalidate content and list
      ref.invalidate(contentItemProvider(id));
      ref.invalidate(contentListProvider);

      return apiResponse.data!;
    } catch (e) {
      throw Exception('Failed to update content: $e');
    }
  }

  /// Delete content
  Future<void> deleteContent(int id) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      await dio.delete('/api/admin/content/$id');

      // Refresh content list
      ref.invalidate(contentListProvider);
    } catch (e) {
      throw Exception('Failed to delete content: $e');
    }
  }

  /// Update content status
  Future<ContentItem> updateStatus(int id, String status) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.put<Map<String, dynamic>>(
        '/api/admin/content/$id/status',
        queryParameters: {'status': status},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? ContentItem.fromJson(data) : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to update status');
      }

      // Invalidate content and list
      ref.invalidate(contentItemProvider(id));
      ref.invalidate(contentListProvider);

      return apiResponse.data!;
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }
}
