import '../../../core/utils/json_utils.dart';

/// Content model matching backend Content entity
class ContentItem {
  ContentItem({
    required this.id,
    this.contentSource,
    this.externalContentId,
    required this.contentType,
    this.durationSeconds,
    this.thumbnailUrl,
    required this.isPremium,
    required this.status,
    this.recordingDate,
    this.recordingLocation,
    this.tags,
    this.contentMetadata,
    required this.viewCount,
    this.averageRating,
    required this.createdAt,
    required this.updatedAt,
    this.audioStreamUrl,
    this.audioFileUrl,
    this.artist,
    this.album,
    // Translation fields (from projection)
    this.title,
    this.description,
    this.language,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json.getInt('id')!,
      contentSource: json.getString('contentSource'),
      externalContentId: json.getString('externalContentId'),
      contentType: _parseContentType(json.getString('contentType')),
      durationSeconds: json.getInt('durationSeconds'),
      thumbnailUrl: json.getString('thumbnailUrl'),
      isPremium: json.getBool('isPremium', defaultValue: false),
      status: _parseContentStatus(json.getString('status')),
      recordingDate: json.getDateTime('recordingDate'),
      recordingLocation: json.getString('recordingLocation'),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      contentMetadata: json.getString('contentMetadata'),
      viewCount: json.getInt('viewCount') ?? 0,
      averageRating: json['averageRating'] != null ? double.parse(json['averageRating'].toString()) : null,
      createdAt: json.getDateTime('createdAt')!,
      updatedAt: json.getDateTime('updatedAt')!,
      audioStreamUrl: json.getString('audioStreamUrl'),
      audioFileUrl: json.getString('audioFileUrl'),
      artist: json.getString('artist'),
      album: json.getString('album'),
      // Translation fields
      title: json.getString('title'),
      description: json.getString('description'),
      language: json.getString('language'),
    );
  }

  final int id;
  final String? contentSource;
  final String? externalContentId;
  final ContentType contentType;
  final int? durationSeconds;
  final String? thumbnailUrl;
  final bool isPremium;
  final ContentStatus status;
  final DateTime? recordingDate;
  final String? recordingLocation;
  final List<String>? tags;
  final String? contentMetadata;
  final int viewCount;
  final double? averageRating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? audioStreamUrl;
  final String? audioFileUrl;
  final String? artist;
  final String? album;

  // Translation fields
  final String? title;
  final String? description;
  final String? language;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentSource': contentSource,
      'externalContentId': externalContentId,
      'contentType': contentType.name.toUpperCase(),
      'durationSeconds': durationSeconds,
      'thumbnailUrl': thumbnailUrl,
      'isPremium': isPremium,
      'status': status.name.toUpperCase(),
      'recordingDate': recordingDate?.toIso8601String(),
      'recordingLocation': recordingLocation,
      'tags': tags,
      'contentMetadata': contentMetadata,
      'viewCount': viewCount,
      'averageRating': averageRating,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'audioStreamUrl': audioStreamUrl,
      'audioFileUrl': audioFileUrl,
      'artist': artist,
      'album': album,
    };
  }

  String get formattedDuration {
    if (durationSeconds == null) return '-';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static ContentType _parseContentType(String? type) {
    if (type == null) return ContentType.VIDEO;
    return ContentType.values.firstWhere(
      (e) => e.name.toUpperCase() == type.toUpperCase(),
      orElse: () => ContentType.VIDEO,
    );
  }

  static ContentStatus _parseContentStatus(String? status) {
    if (status == null) return ContentStatus.PROCESSING;
    return ContentStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == status.toUpperCase(),
      orElse: () => ContentStatus.PROCESSING,
    );
  }
}

// ignore: constant_identifier_names
enum ContentType { VIDEO, AUDIO }

// ignore: constant_identifier_names
enum ContentStatus { ACTIVE, INACTIVE, PROCESSING }
