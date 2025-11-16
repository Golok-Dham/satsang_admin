import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:satsang_admin/core/services/api_service.dart';
import 'package:satsang_admin/features/categories/models/category_model.dart';

part 'categories_provider.g.dart';

/// Categories provider - returns simple list (no backend pagination) from admin endpoint
@riverpod
Future<Map<String, dynamic>> categories(Ref ref, {int page = 0, int size = 50, String? search}) async {
  final apiService = ref.watch(apiServiceProvider);

  final response = await apiService.dio.get('/api/admin/categories');

  if (response.statusCode == 200) {
    final data = response.data as Map<String, dynamic>;
    final apiData = data['data'];

    // Admin categories API returns a list with both English and Hindi translations
    if (apiData is List) {
      final allCategories = apiData.map((json) => CategoryItem.fromJson(json as Map<String, dynamic>)).toList();

      // Apply search filter if needed (search in both English and Hindi)
      var filteredCategories = allCategories;
      if (search != null && search.isNotEmpty) {
        filteredCategories = allCategories.where((category) {
          final searchLower = search.toLowerCase();
          return category.nameEn.toLowerCase().contains(searchLower) ||
              category.nameHi.toLowerCase().contains(searchLower) ||
              (category.descriptionEn?.toLowerCase().contains(searchLower) ?? false) ||
              (category.descriptionHi?.toLowerCase().contains(searchLower) ?? false);
        }).toList();
      }

      // Apply manual pagination
      final start = page * size;
      final end = (start + size).clamp(0, filteredCategories.length);
      final paginatedList = start < filteredCategories.length
          ? filteredCategories.sublist(start, end)
          : <CategoryItem>[];

      return {
        'content': paginatedList,
        'totalElements': filteredCategories.length,
        'totalPages': (filteredCategories.length / size).ceil(),
        'currentPage': page,
      };
    }
  }

  throw Exception('Failed to load categories');
}

/// Category repository for CRUD operations
class CategoryRepository {
  CategoryRepository(this.apiService);

  final ApiService apiService;

  /// Get category by ID
  Future<CategoryItem> getCategoryById(int id) async {
    final response = await apiService.dio.get('/api/admin/categories/$id');

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      return CategoryItem.fromJson(data['data'] as Map<String, dynamic>);
    }

    throw Exception('Failed to load category');
  }

  /// Create new category
  Future<CategoryItem> createCategory(CategoryItem category) async {
    final response = await apiService.dio.post(
      '/api/admin/categories',
      data: {
        'nameEn': category.nameEn,
        'nameHi': category.nameHi,
        'descriptionEn': category.descriptionEn,
        'descriptionHi': category.descriptionHi,
        'sortOrder': category.sortOrder,
        'isActive': category.isActive,
        'parentId': category.parentId,
        'categoryMetadata': category.categoryMetadata,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data as Map<String, dynamic>;
      return CategoryItem.fromJson(data['data'] as Map<String, dynamic>);
    }

    throw Exception('Failed to create category');
  }

  /// Update existing category
  Future<CategoryItem> updateCategory(int id, CategoryItem category) async {
    final response = await apiService.dio.put(
      '/api/admin/categories/$id',
      data: {
        'nameEn': category.nameEn,
        'nameHi': category.nameHi,
        'descriptionEn': category.descriptionEn,
        'descriptionHi': category.descriptionHi,
        'sortOrder': category.sortOrder,
        'isActive': category.isActive,
        'parentId': category.parentId,
        'categoryMetadata': category.categoryMetadata,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      return CategoryItem.fromJson(data['data'] as Map<String, dynamic>);
    }

    throw Exception('Failed to update category');
  }

  /// Delete category
  Future<void> deleteCategory(int id) async {
    final response = await apiService.dio.delete('/api/admin/categories/$id');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete category');
    }
  }

  /// Toggle category active status
  Future<CategoryItem> toggleActive(int id, bool isActive) async {
    final response = await apiService.dio.patch(
      '/api/admin/categories/$id/active',
      queryParameters: {'isActive': isActive},
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      return CategoryItem.fromJson(data['data'] as Map<String, dynamic>);
    }

    throw Exception('Failed to toggle category status');
  }
}

@riverpod
CategoryRepository categoryRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CategoryRepository(apiService);
}
