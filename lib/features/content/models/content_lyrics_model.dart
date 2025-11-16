/// Content Lyrics model matching backend ContentLyrics entity
/// Single object per content with all languages in separate fields
class ContentLyrics {
  ContentLyrics({
    this.id,
    required this.contentId,
    this.hindiLyrics,
    this.englishLyrics,
    this.hindiMeaning,
    this.englishMeaning,
    this.timestampedData,
    this.hasTimestamps,
  });

  factory ContentLyrics.fromJson(Map<String, dynamic> json) {
    return ContentLyrics(
      id: json['id'] as int?,
      contentId: json['contentId'] as int,
      hindiLyrics: json['hindiLyrics'] as String?,
      englishLyrics: json['englishLyrics'] as String?,
      hindiMeaning: json['hindiMeaning'] as String?,
      englishMeaning: json['englishMeaning'] as String?,
      timestampedData: json['timestampedData'] as String?,
      hasTimestamps: json['hasTimestamps'] as bool?,
    );
  }

  final int? id;
  final int contentId;
  final String? hindiLyrics;
  final String? englishLyrics;
  final String? hindiMeaning;
  final String? englishMeaning;
  final String? timestampedData;
  final bool? hasTimestamps;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'contentId': contentId,
      if (hindiLyrics != null) 'hindiLyrics': hindiLyrics,
      if (englishLyrics != null) 'englishLyrics': englishLyrics,
      if (hindiMeaning != null) 'hindiMeaning': hindiMeaning,
      if (englishMeaning != null) 'englishMeaning': englishMeaning,
      if (timestampedData != null) 'timestampedData': timestampedData,
      if (hasTimestamps != null) 'hasTimestamps': hasTimestamps,
    };
  }
}
