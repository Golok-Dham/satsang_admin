import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/api_models.dart';
import '../../../core/services/api_service.dart';
import '../models/quiz_model.dart';

part 'quizzes_provider.g.dart';

/// Provider for paginated quiz list
@riverpod
class QuizzesList extends _$QuizzesList {
  @override
  Future<PagedResponse<QuizListItem>> build({
    int page = 0,
    int size = 20,
    String? search,
    bool? isActive,
    String sortBy = 'createdAt',
    String sortDir = 'desc',
  }) async {
    final dio = ref.read(apiServiceProvider).dio;

    final queryParams = <String, dynamic>{'page': page, 'size': size, 'sortBy': sortBy, 'sortDir': sortDir};

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive;
    }

    try {
      final response = await dio.get<Map<String, dynamic>>('/api/admin/quizzes', queryParameters: queryParams);

      final apiResponse = ApiResponse.fromJson(response.data!, (data) {
        if (data is! Map<String, dynamic>) return null;
        return PagedResponse<QuizListItem>.fromJson(
          data,
          (json) => QuizListItem.fromJson(json as Map<String, dynamic>),
        );
      });

      return apiResponse.data ?? PagedResponse(content: [], totalElements: 0, totalPages: 0, size: size, number: page);
    } catch (e) {
      throw Exception('Failed to load quizzes: $e');
    }
  }

  /// Refresh quizzes list
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for single quiz detail
@riverpod
Future<QuizDetail> quizDetail(Ref ref, int quizId) async {
  final dio = ref.read(apiServiceProvider).dio;

  try {
    final response = await dio.get<Map<String, dynamic>>('/api/admin/quizzes/$quizId');

    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => data is Map<String, dynamic> ? QuizDetail.fromJson(data) : null,
    );

    if (apiResponse.data == null) {
      throw Exception('Quiz not found');
    }

    return apiResponse.data!;
  } catch (e) {
    throw Exception('Failed to load quiz: $e');
  }
}

/// Provider for quiz actions (create, update, delete, toggle)
@riverpod
class QuizActions extends _$QuizActions {
  @override
  void build() {}

  /// Create a new quiz
  Future<Map<String, dynamic>> createQuiz({
    required int contentId,
    String? titleEn,
    String? titleHi,
    String? descriptionEn,
    String? descriptionHi,
    bool isActive = true,
    required List<Map<String, dynamic>> questions,
  }) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final payload = {
        'contentId': contentId,
        'titleEn': titleEn,
        'titleHi': titleHi,
        'descriptionEn': descriptionEn,
        'descriptionHi': descriptionHi,
        'isActive': isActive,
        'questions': questions,
      };

      final response = await dio.post<Map<String, dynamic>>('/api/admin/quizzes', data: payload);

      // Refresh quizzes list
      ref.invalidate(quizzesListProvider);

      return response.data!['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create quiz: $e');
    }
  }

  /// Update an existing quiz
  Future<Map<String, dynamic>> updateQuiz({
    required int quizId,
    String? titleEn,
    String? titleHi,
    String? descriptionEn,
    String? descriptionHi,
    bool? isActive,
    List<Map<String, dynamic>>? questions,
  }) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final payload = <String, dynamic>{};
      if (titleEn != null) payload['titleEn'] = titleEn;
      if (titleHi != null) payload['titleHi'] = titleHi;
      if (descriptionEn != null) payload['descriptionEn'] = descriptionEn;
      if (descriptionHi != null) payload['descriptionHi'] = descriptionHi;
      if (isActive != null) payload['isActive'] = isActive;
      if (questions != null) payload['questions'] = questions;

      final response = await dio.put<Map<String, dynamic>>('/api/admin/quizzes/$quizId', data: payload);

      // Invalidate quiz and list
      ref.invalidate(quizDetailProvider(quizId));
      ref.invalidate(quizzesListProvider);

      return response.data!['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update quiz: $e');
    }
  }

  /// Delete a quiz (ADMIN only)
  Future<void> deleteQuiz(int quizId) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      await dio.delete('/api/admin/quizzes/$quizId');

      // Refresh quizzes list
      ref.invalidate(quizzesListProvider);
    } catch (e) {
      throw Exception('Failed to delete quiz: $e');
    }
  }

  /// Toggle quiz active status
  Future<QuizListItem> toggleActive(int quizId) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.put<Map<String, dynamic>>('/api/admin/quizzes/$quizId/toggle-active');

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? QuizListItem.fromJson(data) : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to toggle quiz status');
      }

      // Invalidate quiz and list
      ref.invalidate(quizDetailProvider(quizId));
      ref.invalidate(quizzesListProvider);

      return apiResponse.data!;
    } catch (e) {
      throw Exception('Failed to toggle quiz status: $e');
    }
  }
}
