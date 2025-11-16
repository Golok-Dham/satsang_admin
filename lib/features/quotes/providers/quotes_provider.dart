import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/api_models.dart';
import '../../../core/services/api_service.dart';

part 'quotes_provider.g.dart';

/// Provider for fetching quotes list with pagination and search
@riverpod
class QuotesList extends _$QuotesList {
  @override
  Future<PagedResponse<DivineQuote>> build({
    int page = 0,
    int size = 50,
    String? category,
    bool? isActive,
    String? search,
  }) async {
    final dio = ref.read(apiServiceProvider).dio;

    final queryParams = <String, dynamic>{'page': page, 'size': size, 'sortBy': 'createdAt', 'sortDir': 'desc'};

    if (category != null) queryParams['category'] = category;
    if (isActive != null) queryParams['isActive'] = isActive;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    try {
      final response = await dio.get<Map<String, dynamic>>('/api/admin/quotes', queryParameters: queryParams);

      final apiResponse = ApiResponse.fromJson(response.data!, (data) {
        if (data is! Map<String, dynamic>) return null;
        return PagedResponse<DivineQuote>.fromJson(data, (json) => DivineQuote.fromJson(json as Map<String, dynamic>));
      });

      return apiResponse.data ?? PagedResponse(content: [], totalElements: 0, totalPages: 0, size: size, number: page);
    } catch (e) {
      throw Exception('Failed to load quotes: $e');
    }
  }

  /// Refresh quotes list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(apiServiceProvider).dio;
      final queryParams = <String, dynamic>{'page': 0, 'size': 50, 'sortBy': 'createdAt', 'sortDir': 'desc'};

      final response = await dio.get<Map<String, dynamic>>('/api/admin/quotes', queryParameters: queryParams);
      final apiResponse = ApiResponse.fromJson(response.data!, (data) {
        if (data is! Map<String, dynamic>) return null;
        return PagedResponse<DivineQuote>.fromJson(data, (json) => DivineQuote.fromJson(json as Map<String, dynamic>));
      });
      return apiResponse.data ?? PagedResponse(content: [], totalElements: 0, totalPages: 0, size: 50, number: 0);
    });
  }
}

/// Provider for a single quote by ID
@riverpod
Future<DivineQuote> quote(Ref ref, int id) async {
  final dio = ref.read(apiServiceProvider).dio;

  try {
    final response = await dio.get<Map<String, dynamic>>('/api/admin/quotes/$id');

    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => data is Map<String, dynamic> ? DivineQuote.fromJson(data) : null,
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
      final response = await dio.post<Map<String, dynamic>>('/api/admin/quotes', data: quote.toJson());

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? DivineQuote.fromJson(data) : null,
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
      final response = await dio.put<Map<String, dynamic>>('/api/admin/quotes/$id', data: quote.toJson());

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? DivineQuote.fromJson(data) : null,
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
      final response = await dio.put<Map<String, dynamic>>('/api/admin/quotes/$id/toggle-active');

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (data) => data is Map<String, dynamic> ? DivineQuote.fromJson(data) : null,
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
        (data) => data is Map<String, dynamic> ? DivineQuote.fromJson(data) : null,
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
