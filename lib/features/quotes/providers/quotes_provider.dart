import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/api_models.dart';
import '../../../core/services/api_service.dart';

part 'quotes_provider.g.dart';

/// Provider for fetching quotes list with pagination
@riverpod
class QuotesList extends _$QuotesList {
  @override
  Future<List<DivineQuote>> build({
    int page = 0,
    int size = 20,
    String? category,
    bool? isActive,
  }) async {
    final dio = ref.read(apiServiceProvider).dio;

    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': 'createdAt',
      'sortDir': 'desc',
    };

    if (category != null) queryParams['category'] = category;
    if (isActive != null) queryParams['isActive'] = isActive;

    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/admin/quotes',
        queryParameters: queryParams,
      );

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) {
          if (data is! Map<String, dynamic>) return null;
          final content = data['content'] as List<dynamic>?;
          if (content == null) return <DivineQuote>[];
          return content
              .map((e) => DivineQuote.fromJson(e as Map<String, dynamic>))
              .toList();
        },
      );

      return apiResponse.data ?? [];
    } catch (e) {
      throw Exception('Failed to load quotes: $e');
    }
  }

  /// Refresh quotes list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(
          page: page,
          size: size,
          category: category,
          isActive: isActive,
        ));
  }
}

/// Provider for a single quote by ID
@riverpod
Future<DivineQuote> quote(Ref ref, int id) async {
  final dio = ref.read(apiServiceProvider).dio;

  try {
    final response = await dio.get<Map<String, dynamic>>(
      '/api/admin/quotes/$id',
    );

    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => data is Map<String, dynamic>
          ? DivineQuote.fromJson(data)
          : null,
    );

    if (apiResponse.data == null) {
      throw Exception('Quote not found');
    }

    return apiResponse.data!;
  } catch (e) {
    throw Exception('Failed to load quote: $e');
  }
}

/// Provider for quote actions (create, update, delete, toggle)
@riverpod
class QuoteActions extends _$QuoteActions {
  @override
  void build() {}

  /// Create a new quote
  Future<DivineQuote> createQuote(DivineQuote quote) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/admin/quotes',
        data: quote.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic>
            ? DivineQuote.fromJson(data)
            : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to create quote');
      }

      // Refresh quotes list
      ref.invalidate(quotesListProvider);

      return apiResponse.data!;
    } catch (e) {
      throw Exception('Failed to create quote: $e');
    }
  }

  /// Update an existing quote
  Future<DivineQuote> updateQuote(int id, DivineQuote quote) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.put<Map<String, dynamic>>(
        '/api/admin/quotes/$id',
        data: quote.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic>
            ? DivineQuote.fromJson(data)
            : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to update quote');
      }

      // Invalidate quote and list
      ref.invalidate(quoteProvider(id));
      ref.invalidate(quotesListProvider);

      return apiResponse.data!;
    } catch (e) {
      throw Exception('Failed to update quote: $e');
    }
  }

  /// Delete a quote
  Future<void> deleteQuote(int id) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      await dio.delete('/api/admin/quotes/$id');

      // Refresh quotes list
      ref.invalidate(quotesListProvider);
    } catch (e) {
      throw Exception('Failed to delete quote: $e');
    }
  }

  /// Toggle quote active status
  Future<DivineQuote> toggleActive(int id) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.put<Map<String, dynamic>>(
        '/api/admin/quotes/$id/toggle-active',
      );

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic>
            ? DivineQuote.fromJson(data)
            : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to toggle quote status');
      }

      // Invalidate quote and list
      ref.invalidate(quoteProvider(id));
      ref.invalidate(quotesListProvider);

      return apiResponse.data!;
    } catch (e) {
      throw Exception('Failed to toggle quote status: $e');
    }
  }

  /// Update quote category
  Future<DivineQuote> updateCategory(int id, String category) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.put<Map<String, dynamic>>(
        '/api/admin/quotes/$id/category',
        queryParameters: {'category': category},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic>
            ? DivineQuote.fromJson(data)
            : null,
      );

      if (apiResponse.data == null) {
        throw Exception('Failed to update category');
      }

      // Invalidate quote and list
      ref.invalidate(quoteProvider(id));
      ref.invalidate(quotesListProvider);

      return apiResponse.data!;
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }
}
