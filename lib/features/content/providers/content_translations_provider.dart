import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/api_service.dart';
import '../models/content_translation_model.dart';

part 'content_translations_provider.g.dart';

/// Provider for fetching content translations
@riverpod
class ContentTranslationsList extends _$ContentTranslationsList {
  @override
  Future<List<ContentTranslation>> build(int contentId) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.get<Map<String, dynamic>>('/api/admin/content/$contentId/translations');

      if (response.data != null && response.data!['success'] == true && response.data!['data'] != null) {
        final List<dynamic> data = response.data!['data'] as List<dynamic>;
        return data.map((json) => ContentTranslation.fromJson(json as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to load translations: $e');
    }
  }

  /// Refresh translations
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(contentId));
  }
}

/// Provider for content translation actions (create/update)
@riverpod
class ContentTranslationsActions extends _$ContentTranslationsActions {
  @override
  FutureOr<void> build() {
    // No-op build
  }

  /// Save translations for a content
  Future<void> saveTranslations(int contentId, List<ContentTranslation> translations) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final dio = ref.read(apiServiceProvider).dio;

      final translationsJson = translations.map((t) => t.toJson()).toList();

      await dio.post<Map<String, dynamic>>('/api/admin/content/$contentId/translations', data: translationsJson);

      // Invalidate the translations list to trigger refresh
      ref.invalidate(contentTranslationsListProvider(contentId));
    });
  }
}
