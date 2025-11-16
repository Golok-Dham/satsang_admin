import 'dart:convert';

import 'category_model.dart';

/// Strongly typed metadata wrapper for category customization fields.
class CategoryMetadata {
  CategoryMetadata({
    this.pillBackgroundHex,
    this.pillTextHex,
    this.iconName,
    this.bannerImageUrl,
    this.thumbnailImageUrl,
    this.taglineEn,
    this.taglineHi,
    Map<String, dynamic>? additionalFields,
  }) : additionalFields = additionalFields == null ? const {} : Map<String, dynamic>.unmodifiable(additionalFields);

  factory CategoryMetadata.empty() => CategoryMetadata();

  factory CategoryMetadata.fromRawJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return CategoryMetadata();
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(decoded);

      String? takeValue(List<String> keys) {
        for (final key in keys) {
          if (data.containsKey(key)) {
            final value = data.remove(key);
            if (value == null) {
              return null;
            }
            return value.toString();
          }
        }
        return null;
      }

      return CategoryMetadata(
        pillBackgroundHex: takeValue(const ['pillBackgroundHex', 'pillBackgroundColor', 'pillColor']),
        pillTextHex: takeValue(const ['pillTextHex', 'pillTextColor']),
        iconName: takeValue(const ['iconName', 'icon']),
        bannerImageUrl: takeValue(const ['bannerImageUrl', 'bannerUrl']),
        thumbnailImageUrl: takeValue(const ['thumbnailImageUrl', 'thumbnailUrl']),
        taglineEn: takeValue(const ['taglineEn', 'tagline']),
        taglineHi: takeValue(const ['taglineHi']),
        additionalFields: data,
      );
    } catch (_) {
      // If metadata is not valid JSON, return empty to avoid crashing the UI.
      return CategoryMetadata();
    }
  }

  final String? pillBackgroundHex;
  final String? pillTextHex;
  final String? iconName;
  final String? bannerImageUrl;
  final String? thumbnailImageUrl;
  final String? taglineEn;
  final String? taglineHi;
  final Map<String, dynamic> additionalFields;

  bool get isEmpty => toMap().isEmpty;

  CategoryMetadata copyWith({
    String? pillBackgroundHex,
    String? pillTextHex,
    String? iconName,
    String? bannerImageUrl,
    String? thumbnailImageUrl,
    String? taglineEn,
    String? taglineHi,
    Map<String, dynamic>? additionalFields,
  }) {
    return CategoryMetadata(
      pillBackgroundHex: pillBackgroundHex ?? this.pillBackgroundHex,
      pillTextHex: pillTextHex ?? this.pillTextHex,
      iconName: iconName ?? this.iconName,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      thumbnailImageUrl: thumbnailImageUrl ?? this.thumbnailImageUrl,
      taglineEn: taglineEn ?? this.taglineEn,
      taglineHi: taglineHi ?? this.taglineHi,
      additionalFields: additionalFields ?? this.additionalFields,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{}..addAll(additionalFields);

    void put(String key, String? value) {
      if (value == null || value.trim().isEmpty) {
        map.remove(key);
      } else {
        map[key] = value.trim();
      }
    }

    put('pillBackgroundHex', _normalizeHex(pillBackgroundHex));
    put('pillTextHex', _normalizeHex(pillTextHex));
    put('iconName', iconName);
    put('bannerImageUrl', bannerImageUrl);
    put('thumbnailImageUrl', thumbnailImageUrl);
    put('taglineEn', taglineEn);
    put('taglineHi', taglineHi);

    return map;
  }

  String toJsonString() {
    final map = toMap();
    if (map.isEmpty) {
      return '{}';
    }
    return jsonEncode(map);
  }

  static String? _normalizeHex(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    final normalized = trimmed.startsWith('#') ? trimmed : '#$trimmed';
    return normalized.toUpperCase();
  }

  static bool isValidHex(String value) {
    final pattern = RegExp(r'^#?[0-9a-fA-F]{6}$');
    return pattern.hasMatch(value.trim());
  }
}

extension CategoryItemMetadataX on CategoryItem {
  CategoryMetadata get metadata => CategoryMetadata.fromRawJson(categoryMetadata);
}
