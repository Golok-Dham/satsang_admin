import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/api_service.dart';
import '../models/content_lyrics_model.dart';

part 'content_lyrics_provider.g.dart';

/// Provider for fetching content lyrics (single object per content)
@riverpod
class ContentLyricsItem extends _$ContentLyricsItem {
  @override
  Future<ContentLyrics?> build(int contentId) async {
    final dio = ref.read(apiServiceProvider).dio;

    try {
      final response = await dio.get<Map<String, dynamic>>('/api/lyrics/content/$contentId');
      if (response.data != null) {
        return ContentLyrics.fromJson(response.data!);
      }
      return null;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// Refresh lyrics
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(contentId));
  }
}

/// Provider for content lyrics actions (create/update)
@riverpod
class ContentLyricsActions extends _$ContentLyricsActions {
  @override
  FutureOr<void> build() {
    // No-op build
  }

  /// Save lyrics for a content
  Future<ContentLyrics> saveLyrics(ContentLyrics lyrics) async {
    state = const AsyncValue.loading();

    try {
      final dio = ref.read(apiServiceProvider).dio;
      final payload = lyrics.id == null ? _buildCreatePayload(lyrics) : _buildUpdatePayload(lyrics);
      final response = lyrics.id == null
          ? await dio.post<Map<String, dynamic>>('/api/lyrics', data: payload)
          : await dio.put<Map<String, dynamic>>('/api/lyrics/${lyrics.id}', data: payload);

      if (response.data == null) {
        throw Exception('Empty response while saving lyrics');
      }

      final saved = ContentLyrics.fromJson(response.data!);
      state = const AsyncValue.data(null);
      ref.invalidate(contentLyricsItemProvider(lyrics.contentId));
      return saved;
    } on DioException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic> _buildCreatePayload(ContentLyrics lyrics) {
    final sanitizedTimestamped = lyrics.timestampedData?.trim() ?? '';
    return {
      'contentId': lyrics.contentId,
      'hindiLyrics': lyrics.hindiLyrics ?? '',
      'englishLyrics': lyrics.englishLyrics ?? '',
      'hindiMeaning': lyrics.hindiMeaning ?? '',
      'englishMeaning': lyrics.englishMeaning ?? '',
      'timestampedData': sanitizedTimestamped,
      'hasTimestamps': lyrics.hasTimestamps ?? sanitizedTimestamped.isNotEmpty,
    };
  }

  Map<String, dynamic> _buildUpdatePayload(ContentLyrics lyrics) {
    final sanitizedTimestamped = lyrics.timestampedData?.trim() ?? '';
    return {
      'hindiLyrics': lyrics.hindiLyrics ?? '',
      'englishLyrics': lyrics.englishLyrics ?? '',
      'hindiMeaning': lyrics.hindiMeaning ?? '',
      'englishMeaning': lyrics.englishMeaning ?? '',
      'timestampedData': sanitizedTimestamped,
      'hasTimestamps': lyrics.hasTimestamps ?? sanitizedTimestamped.isNotEmpty,
    };
  }
}
