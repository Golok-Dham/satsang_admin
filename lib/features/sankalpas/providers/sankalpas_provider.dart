import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/api_models.dart';
import '../../../core/services/api_service.dart';
import '../models/sankalp_template_model.dart';

part 'sankalpas_provider.g.dart';

/// Provider for fetching sankalp templates list with pagination and filters
@riverpod
class SankalpTemplatesList extends _$SankalpTemplatesList {
  @override
  Future<PagedResponse<SankalpTemplate>> build({
    int page = 0,
    int size = 50,
    String? sankalpType,
    bool? isSystemTemplate,
    String? search,
  }) async {
    final dio = ref.read(apiServiceProvider).dio;

    final queryParams = <String, dynamic>{'page': page, 'size': size, 'sortBy': 'displayOrder', 'sortDir': 'asc'};

    if (sankalpType != null) queryParams['sankalpType'] = sankalpType;
    if (isSystemTemplate != null) queryParams['isSystemTemplate'] = isSystemTemplate;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    try {
      final response = await dio.get<Map<String, dynamic>>('/api/admin/sankalpas', queryParameters: queryParams);

      final apiResponse = ApiResponse.fromJson(response.data!, (data) {
        if (data is! Map<String, dynamic>) return null;
        return PagedResponse<SankalpTemplate>.fromJson(
          data,
          (json) => SankalpTemplate.fromJson(json as Map<String, dynamic>),
        );
      });

      return apiResponse.data ?? PagedResponse(content: [], totalElements: 0, totalPages: 0, size: size, number: page);
    } catch (e) {
      throw Exception('Failed to load sankalp templates: $e');
    }
  }

  /// Refresh templates list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(apiServiceProvider).dio;
      final queryParams = <String, dynamic>{'page': 0, 'size': 50, 'sortBy': 'displayOrder', 'sortDir': 'asc'};

      final response = await dio.get<Map<String, dynamic>>('/api/admin/sankalpas', queryParameters: queryParams);
      final apiResponse = ApiResponse.fromJson(response.data!, (data) {
        if (data is! Map<String, dynamic>) return null;
        return PagedResponse<SankalpTemplate>.fromJson(
          data,
          (json) => SankalpTemplate.fromJson(json as Map<String, dynamic>),
        );
      });
      return apiResponse.data ?? PagedResponse(content: [], totalElements: 0, totalPages: 0, size: 50, number: 0);
    });
  }
}

/// Provider for a single sankalp template by ID
@riverpod
Future<SankalpTemplate> sankalpTemplate(Ref ref, int id) async {
  final dio = ref.read(apiServiceProvider).dio;

  try {
    final response = await dio.get<Map<String, dynamic>>('/api/admin/sankalpas/$id');

    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => data is Map<String, dynamic> ? SankalpTemplate.fromJson(data) : null,
    );

    if (apiResponse.data == null) {
      throw Exception('Sankalp template not found');
    }

    return apiResponse.data!;
  } catch (e) {
    throw Exception('Failed to load sankalp template: $e');
  }
}

/// Provider for sankalp template actions (create, update, delete, toggle)
@riverpod
class SankalpTemplateActions extends _$SankalpTemplateActions {
  @override
  void build() {}

  /// Create a new sankalp template
  Future<SankalpTemplate> createTemplate(SankalpTemplate template) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.post<Map<String, dynamic>>('/api/admin/sankalpas', data: template.toJson());

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? SankalpTemplate.fromJson(data) : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to create sankalp template');
      }

      // Refresh templates list
      ref.invalidate(sankalpTemplatesListProvider);

      return apiResponse.data!;
    } catch (e) {
      throw Exception('Failed to create sankalp template: $e');
    }
  }

  /// Update an existing sankalp template
  Future<SankalpTemplate> updateTemplate(int id, SankalpTemplate template) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.put<Map<String, dynamic>>('/api/admin/sankalpas/$id', data: template.toJson());

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? SankalpTemplate.fromJson(data) : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to update sankalp template');
      }

      // Invalidate template and list
      ref.invalidate(sankalpTemplateProvider(id));
      ref.invalidate(sankalpTemplatesListProvider);

      return apiResponse.data!;
    } catch (e) {
      throw Exception('Failed to update sankalp template: $e');
    }
  }

  /// Delete a sankalp template
  Future<void> deleteTemplate(int id) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      await dio.delete('/api/admin/sankalpas/$id');

      // Refresh templates list
      ref.invalidate(sankalpTemplatesListProvider);
    } catch (e) {
      throw Exception('Failed to delete sankalp template: $e');
    }
  }

  /// Toggle system template status
  Future<SankalpTemplate> toggleSystemTemplate(int id) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.put<Map<String, dynamic>>('/api/admin/sankalpas/$id/toggle-system');

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? SankalpTemplate.fromJson(data) : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to toggle system template status');
      }

      // Invalidate template and list
      ref.invalidate(sankalpTemplateProvider(id));
      ref.invalidate(sankalpTemplatesListProvider);

      return apiResponse.data!;
    } catch (e) {
      throw Exception('Failed to toggle system template status: $e');
    }
  }

  /// Update display order
  Future<SankalpTemplate> updateDisplayOrder(int id, int displayOrder) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.put<Map<String, dynamic>>(
        '/api/admin/sankalpas/$id/order',
        queryParameters: {'displayOrder': displayOrder},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? SankalpTemplate.fromJson(data) : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to update display order');
      }

      // Invalidate template and list
      ref.invalidate(sankalpTemplateProvider(id));
      ref.invalidate(sankalpTemplatesListProvider);

      return apiResponse.data!;
    } catch (e) {
      throw Exception('Failed to update display order: $e');
    }
  }
}
