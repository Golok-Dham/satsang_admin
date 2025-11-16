/// User model for admin panel
class UserItem {
  final int id;
  final String firebaseUid;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final UserStatus status;
  final SubscriptionType subscriptionType;
  final UserRole role;
  final DateTime? subscriptionExpiryDate;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final String preferredLanguage;
  final int maxConcurrentSessions;
  final DateTime? lastLoginTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserItem({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.photoUrl,
    required this.status,
    required this.subscriptionType,
    required this.role,
    this.subscriptionExpiryDate,
    required this.isPhoneVerified,
    required this.isEmailVerified,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    required this.preferredLanguage,
    required this.maxConcurrentSessions,
    this.lastLoginTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      id: json['id'] as int,
      firebaseUid: json['firebaseUid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
      status: UserStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status'] as String).toUpperCase(),
        orElse: () => UserStatus.active,
      ),
      subscriptionType: SubscriptionType.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['subscriptionType'] as String).toUpperCase(),
        orElse: () => SubscriptionType.free,
      ),
      role: UserRole.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['role'] as String).toUpperCase(),
        orElse: () => UserRole.user,
      ),
      subscriptionExpiryDate: json['subscriptionExpiryDate'] != null
          ? DateTime.parse(json['subscriptionExpiryDate'] as String)
          : null,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      emailVerifiedAt: json['emailVerifiedAt'] != null ? DateTime.parse(json['emailVerifiedAt'] as String) : null,
      phoneVerifiedAt: json['phoneVerifiedAt'] != null ? DateTime.parse(json['phoneVerifiedAt'] as String) : null,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      maxConcurrentSessions: json['maxConcurrentSessions'] as int? ?? 2,
      lastLoginTime: json['lastLoginTime'] != null ? DateTime.parse(json['lastLoginTime'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'status': status.name.toUpperCase(),
      'subscriptionType': subscriptionType.name.toUpperCase(),
      'role': role.name.toUpperCase(),
      'subscriptionExpiryDate': subscriptionExpiryDate?.toIso8601String(),
      'isPhoneVerified': isPhoneVerified,
      'isEmailVerified': isEmailVerified,
      'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
      'phoneVerifiedAt': phoneVerifiedAt?.toIso8601String(),
      'preferredLanguage': preferredLanguage,
      'maxConcurrentSessions': maxConcurrentSessions,
      'lastLoginTime': lastLoginTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isPremium =>
      subscriptionType == SubscriptionType.premium || subscriptionType == SubscriptionType.premiumPlus;

  bool get isActive => status == UserStatus.active;

  bool get isVerified => isEmailVerified && isPhoneVerified;
}

enum UserStatus { active, suspended, inactive }

enum SubscriptionType { free, premium, premiumPlus }

enum UserRole { user, moderator, admin }

/// Paginated user list response
class PaginatedUsers {
  final List<UserItem> content;
  final int totalElements;
  final int totalPages;
  final int number; // Current page number
  final int size; // Page size
  final bool first;
  final bool last;

  PaginatedUsers({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
  });

  factory PaginatedUsers.fromJson(Map<String, dynamic> json) {
    return PaginatedUsers(
      content: (json['content'] as List<dynamic>)
          .map((item) => UserItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      number: json['number'] as int,
      size: json['size'] as int,
      first: json['first'] as bool,
      last: json['last'] as bool,
    );
  }
}
