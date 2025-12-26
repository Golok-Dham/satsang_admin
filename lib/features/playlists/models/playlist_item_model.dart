import '../../../core/utils/json_utils.dart';

/// Playlist item model for admin management
class PlaylistItemModel {
  final int id;
  final int playlistId;
  final int contentId;
  final String contentTitle;
  final String? contentThumbnail;
  final String? contentType;
  final int? durationSeconds;
  final int sortOrder;
  final DateTime? addedAt;

  const PlaylistItemModel({
    required this.id,
    required this.playlistId,
    required this.contentId,
    required this.contentTitle,
    this.contentThumbnail,
    this.contentType,
    this.durationSeconds,
    required this.sortOrder,
    this.addedAt,
  });

  /// Get formatted duration string (e.g., "1:23:45" or "23:45")
  String get formattedDuration {
    if (durationSeconds == null || durationSeconds == 0) return '-';

    final hours = durationSeconds! ~/ 3600;
    final minutes = (durationSeconds! % 3600) ~/ 60;
    final seconds = durationSeconds! % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory PlaylistItemModel.fromJson(Map<String, dynamic> json) {
    return PlaylistItemModel(
      id: JsonUtils.asInt(json['id']) ?? 0,
      playlistId: JsonUtils.asInt(json['playlistId']) ?? 0,
      contentId: JsonUtils.asInt(json['contentId']) ?? 0,
      contentTitle: json['contentTitle'] as String? ?? 'Untitled',
      contentThumbnail: json['contentThumbnail'] as String?,
      contentType: json['contentType'] as String?,
      durationSeconds: JsonUtils.asInt(json['durationSeconds']),
      sortOrder: JsonUtils.asInt(json['sortOrder']) ?? 0,
      addedAt: JsonUtils.parseDateTime(json['addedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playlistId': playlistId,
      'contentId': contentId,
      'contentTitle': contentTitle,
      'contentThumbnail': contentThumbnail,
      'contentType': contentType,
      'durationSeconds': durationSeconds,
      'sortOrder': sortOrder,
      'addedAt': addedAt?.toIso8601String(),
    };
  }

  PlaylistItemModel copyWith({
    int? id,
    int? playlistId,
    int? contentId,
    String? contentTitle,
    String? contentThumbnail,
    String? contentType,
    int? durationSeconds,
    int? sortOrder,
    DateTime? addedAt,
  }) {
    return PlaylistItemModel(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      contentId: contentId ?? this.contentId,
      contentTitle: contentTitle ?? this.contentTitle,
      contentThumbnail: contentThumbnail ?? this.contentThumbnail,
      contentType: contentType ?? this.contentType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sortOrder: sortOrder ?? this.sortOrder,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
