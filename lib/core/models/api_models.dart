import '../utils/json_utils.dart';

/// API Response wrapper matching backend format
class ApiResponse<T> {
  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json.getBool('success'),
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      error: json['error'] != null
          ? ApiError.fromJson(json.getMap('error')!)
          : null,
      message: json.getString('message'),
      timestamp: json.getString('timestamp') ?? '',
    );
  }
  final bool success;
  final T? data;
  final ApiError? error;
  final String? message;
  final String timestamp;

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'error': error?.toJson(),
      'message': message,
      'timestamp': timestamp,
    };
  }
}

/// API Error structure
class ApiError {
  ApiError({required this.code, required this.message, this.details});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json.getString('code') ?? 'UNKNOWN_ERROR',
      message: json.getString('message') ?? 'An unknown error occurred',
      details: json.getMap('details'),
    );
  }
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  Map<String, dynamic> toJson() {
    return {'code': code, 'message': message, 'details': details};
  }
}

/// User Profile Model
class UserProfile {
  UserProfile({
    required this.firebaseUid,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profilePictureUrl,
    this.preferredLanguage,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firebaseUid: json.getString('firebaseUid')!,
      email: json.getString('email')!,
      displayName: json.getString('displayName'),
      firstName: json.getString('firstName'),
      lastName: json.getString('lastName'),
      phoneNumber: json.getString('phoneNumber'),
      profilePictureUrl: json.getString('profilePictureUrl'),
      preferredLanguage: json.getString('preferredLanguage'),
      isActive: json.getBool('isActive', defaultValue: true),
      createdAt: json.getDateTime('createdAt')!,
      lastLoginAt: json.getDateTime('lastLoginAt'),
    );
  }
  final String firebaseUid;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profilePictureUrl;
  final String? preferredLanguage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  Map<String, dynamic> toJson() {
    return {
      'firebaseUid': firebaseUid,
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'preferredLanguage': preferredLanguage,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }
}

/// Content Category Model
class ContentCategory {
  ContentCategory({
    required this.id,
    required this.name,
    this.description,
    required this.sortOrder,
    required this.isActive,
    this.parentId,
    this.categoryMetadata,
    this.createdAt,
  });

  factory ContentCategory.fromJson(Map<String, dynamic> json) {
    return ContentCategory(
      id: json.getInt('id')!,
      name: json.getString('name')!,
      description: json.getString('description'),
      sortOrder: json.getInt('sortOrder') ?? 0,
      isActive: json.getBool('isActive', defaultValue: true),
      parentId: json.getInt('parentId'),
      categoryMetadata: json.getString('categoryMetadata'),
      createdAt: json.getDateTime('createdAt'),
    );
  }
  final int id;
  final String name;
  final String? description;
  final int sortOrder;
  final bool isActive;
  final int? parentId;
  final String? categoryMetadata;
  final DateTime? createdAt;
}

/// Content Model
class Content {
  Content({
    required this.id,
    required this.title,
    this.description,
    this.contentSource, // 'VDOCIPHER', 'YOUTUBE', etc.
    this.externalContentId, // Video ID from external source
    required this.contentType,
    this.durationSeconds,
    this.thumbnailUrl,
    this.categoryId,
    this.isPremium,
    this.status,
    this.recordingDate,
    this.recordingLocation,
    this.tags,
    this.viewCount,
    this.averageRating,
    this.createdAt,
    this.updatedAt,
    this.isSadhanaContent = false,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json.getInt('id')!,
      title: json.getString('title') ?? 'Untitled',
      description: json.getString('description'),
      contentSource: json.getString('contentSource'),
      externalContentId: json.getString('externalContentId'),
      contentType: json.getString('contentType') ?? 'video',
      durationSeconds: json.getInt('durationSeconds'),
      thumbnailUrl: json.getString('thumbnailUrl'),
      categoryId: json.getInt('categoryId'),
      isPremium: json.getBool('isPremium', defaultValue: false),
      status: json.getString('status'),
      recordingDate: json.getDateTime('recordingDate'),
      recordingLocation: json.getString('recordingLocation'),
      tags: json.getList('tags', (tag) => tag as String),
      viewCount: json.getInt('viewCount'),
      averageRating: json.getDouble('averageRating'),
      createdAt: json.getDateTime('createdAt'),
      updatedAt: json.getDateTime('updatedAt'),
      isSadhanaContent: json.getBool('isSadhanaContent', defaultValue: false),
    );
  }
  final int id;
  final String title;
  final String? description;
  final String? contentSource; // Source platform (VDOCIPHER, YOUTUBE, etc.)
  final String? externalContentId; // Video ID from external platform
  final String contentType; // 'VIDEO' or 'AUDIO'
  final int? durationSeconds;
  final String? thumbnailUrl;
  final int? categoryId;
  final bool? isPremium;
  final String? status;
  final DateTime? recordingDate;
  final String? recordingLocation;
  final List<String>? tags;
  final int? viewCount;
  final double? averageRating;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSadhanaContent;
}

/// vdoCipher Stream Token Response
class StreamToken {
  StreamToken({
    required this.otp,
    required this.playbackInfo,
    required this.videoId,
    required this.expires,
    required this.annotations,
  });

  factory StreamToken.fromJson(Map<String, dynamic> json) {
    return StreamToken(
      otp: json.getString('otp')!,
      playbackInfo: json.getString('playbackInfo')!,
      videoId: json.getString('videoId')!,
      expires: json.getInt('expires')!,
      annotations: json['annotations'] as List<dynamic>? ?? [],
    );
  }
  final String otp;
  final String playbackInfo;
  final String videoId;
  final int expires;
  final List<dynamic> annotations;
}

/// Playlist Model
class Playlist {
  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.isPublic,
    required this.contentCount,
    required this.contentType,
    required this.createdAt,
    required this.updatedAt,
    this.previewThumbnails,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json.getInt('id')!,
      name: json.getString('name')!,
      description: json.getString('description'),
      isPublic: json.getBool('isPublic'),
      contentCount: json.getInt('contentCount') ?? 0,
      contentType: json.getString('contentType') ?? 'VIDEO',
      createdAt: json.getDateTime('createdAt')!,
      updatedAt: json.getDateTime('updatedAt')!,
      previewThumbnails: json.getList('previewThumbnails', (e) => e as String),
    );
  }
  final int id;
  final String name;
  final String? description;
  final bool isPublic;
  final int contentCount;
  final String contentType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? previewThumbnails;
}

/// Progress Model
class ProgressData {
  ProgressData({
    required this.contentId,
    required this.currentPositionSeconds,
    this.totalDurationSeconds,
    required this.isCompleted,
    required this.lastWatchedAt,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      contentId: json.getInt('contentId')!,
      currentPositionSeconds: json.getInt('currentPositionSeconds') ?? 0,
      totalDurationSeconds: json.getInt('totalDurationSeconds'),
      isCompleted: json.getBool('isCompleted'),
      lastWatchedAt: json.getDateTime('lastWatchedAt')!,
    );
  }
  final int contentId;
  final int currentPositionSeconds;
  final int? totalDurationSeconds;
  final bool isCompleted;
  final DateTime lastWatchedAt;

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'currentPositionSeconds': currentPositionSeconds,
      'isCompleted': isCompleted,
    };
  }
}

/// Divine Quote Model
class DivineQuote {
  DivineQuote({
    required this.id,
    required this.textDevanagari,
    this.textTransliteration,
    this.textHindiMeaning,
    required this.textEnglishMeaning,
    required this.sourceBook,
    this.verseNumber,
    required this.category,
    this.displayPriority,
    this.favoriteCount = 0,
    this.shareCount = 0,
    required this.isActive,
    this.isFavorited,
    required this.createdAt,
    this.updatedAt,
  });

  factory DivineQuote.fromJson(Map<String, dynamic> json) {
    return DivineQuote(
      id: json.getInt('id')!,
      textDevanagari: json.getString('textDevanagari')!,
      textTransliteration: json.getString('textTransliteration'),
      textHindiMeaning: json.getString('textHindiMeaning'),
      textEnglishMeaning: json.getString('textEnglishMeaning')!,
      sourceBook: json.getString('sourceBook')!,
      verseNumber: json.getString('verseNumber'),
      category: json.getString('category')!,
      displayPriority: json.getInt('displayPriority'),
      favoriteCount: json.getInt('favoriteCount') ?? 0,
      shareCount: json.getInt('shareCount') ?? 0,
      isActive: json.getBool('isActive', defaultValue: true),
      isFavorited: json.getBool('isFavorited'),
      createdAt: json.getDateTime('createdAt')!,
      updatedAt: json.getDateTime('updatedAt'),
    );
  }
  final int id;
  final String textDevanagari; // Original Devanagari/Sanskrit text
  final String? textTransliteration; // Roman script representation
  final String? textHindiMeaning; // Hindi explanation/meaning (bhavarth)
  final String textEnglishMeaning; // English explanation/meaning
  final String sourceBook;
  final String? verseNumber;
  final String category; // 'bhakti', 'vairagya', 'gyaan', 'prema', 'sadhana'
  final int? displayPriority;
  final int favoriteCount;
  final int shareCount;
  final bool isActive;
  final bool? isFavorited; // Favorite status for current user
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'textDevanagari': textDevanagari,
      'textTransliteration': textTransliteration,
      'textHindiMeaning': textHindiMeaning,
      'textEnglishMeaning': textEnglishMeaning,
      'sourceBook': sourceBook,
      'verseNumber': verseNumber,
      'category': category,
      'displayPriority': displayPriority,
      'favoriteCount': favoriteCount,
      'shareCount': shareCount,
      'isActive': isActive,
      'isFavorited': isFavorited,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Quote User Preference Model
class QuoteUserPreference {
  QuoteUserPreference({
    required this.userId,
    this.showOnAppLaunch,
    this.showPeriodicPopups,
    this.popupIntervalMinutes,
    this.preferredLanguage,
    this.showTranslation,
    this.dndUntil,
    this.lastPopupShownAt,
    this.disabledUntil,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory QuoteUserPreference.fromJson(Map<String, dynamic> json) {
    return QuoteUserPreference(
      userId: json.getInt('userId')!,
      showOnAppLaunch: json.getBool('showOnAppLaunch'),
      showPeriodicPopups: json.getBool('showPeriodicPopups'),
      popupIntervalMinutes: json.getInt('popupIntervalMinutes'),
      preferredLanguage: json.getString('preferredLanguage'),
      showTranslation: json.getBool('showTranslation'),
      dndUntil: json.getDateTime('dndUntil'),
      lastPopupShownAt: json.getDateTime('lastPopupShownAt'),
      // Backend sends 'disabledUntilDate', frontend uses 'disabledUntil'
      disabledUntil: json.getDateTime('disabledUntilDate'),
      createdAt: json.getDateTime('createdAt') ?? DateTime.now(),
      updatedAt: json.getDateTime('updatedAt'),
    );
  }
  final int userId;
  final bool? showOnAppLaunch;
  final bool? showPeriodicPopups;
  final int? popupIntervalMinutes;
  final String? preferredLanguage; // 'hi', 'en' - Independent of app language
  final bool? showTranslation;
  final DateTime? dndUntil;
  final DateTime? lastPopupShownAt;
  final DateTime? disabledUntil;
  final DateTime createdAt; // Now defaults to DateTime.now() if null
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'showOnAppLaunch': showOnAppLaunch,
      'showPeriodicPopups': showPeriodicPopups,
      'popupIntervalMinutes': popupIntervalMinutes,
      'preferredLanguage': preferredLanguage,
      'showTranslation': showTranslation,
      'dndUntil': dndUntil?.toIso8601String(),
      'lastPopupShownAt': lastPopupShownAt?.toIso8601String(),
      'disabledUntil': disabledUntil?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Check if user is in Do Not Disturb mode
  bool get isInDndMode {
    if (dndUntil == null) return false;
    return DateTime.now().isBefore(dndUntil!);
  }

  /// Check if quotes are temporarily disabled
  bool get isDisabled {
    if (disabledUntil == null) return false;
    return DateTime.now().isBefore(disabledUntil!);
  }
}

/// Update Quote Preference Request Model
class UpdateQuotePreferenceRequest {
  UpdateQuotePreferenceRequest({
    this.showOnAppLaunch,
    this.showPeriodicPopups,
    this.popupIntervalMinutes,
    this.preferredLanguage,
    this.showTranslation,
    this.dndUntil,
    this.disabledUntil,
  });

  factory UpdateQuotePreferenceRequest.fromJson(Map<String, dynamic> json) {
    return UpdateQuotePreferenceRequest(
      showOnAppLaunch: json.getBool('showOnAppLaunch'),
      showPeriodicPopups: json.getBool('showPeriodicPopups'),
      popupIntervalMinutes: json.getInt('popupIntervalMinutes'),
      preferredLanguage: json.getString('preferredLanguage'),
      showTranslation: json.getBool('showTranslation'),
      dndUntil: json.getDateTime('dndUntil'),
      disabledUntil: json.getDateTime('disabledUntil'),
    );
  }
  final bool? showOnAppLaunch;
  final bool? showPeriodicPopups;
  final int? popupIntervalMinutes;
  final String? preferredLanguage;
  final bool? showTranslation;
  final DateTime? dndUntil;
  final DateTime? disabledUntil;

  Map<String, dynamic> toJson() {
    return {
      'showOnAppLaunch': showOnAppLaunch,
      'showPeriodicPopups': showPeriodicPopups,
      'popupIntervalMinutes': popupIntervalMinutes,
      'preferredLanguage': preferredLanguage,
      'showTranslation': showTranslation,
      'dndUntil': dndUntil?.toIso8601String(),
      'disabledUntil': disabledUntil?.toIso8601String(),
    };
  }
}
