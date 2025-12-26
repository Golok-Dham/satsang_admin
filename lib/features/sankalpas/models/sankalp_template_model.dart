import '../../../core/utils/json_utils.dart';

/// Sankalp Type enum matching backend SankalpType
// ignore: constant_identifier_names
enum SankalpType {
  // ignore: constant_identifier_names
  TIME_BASED,
  // ignore: constant_identifier_names
  COUNT_BASED,
  // ignore: constant_identifier_names
  BOOLEAN,
  // ignore: constant_identifier_names
  ROOPDHYAN_SPECIAL;

  String get displayName {
    switch (this) {
      case SankalpType.TIME_BASED:
        return 'Time Based';
      case SankalpType.COUNT_BASED:
        return 'Count Based';
      case SankalpType.BOOLEAN:
        return 'Yes/No';
      case SankalpType.ROOPDHYAN_SPECIAL:
        return 'Roopdhyan Special';
    }
  }

  static SankalpType fromString(String value) {
    return SankalpType.values.firstWhere((e) => e.name == value.toUpperCase(), orElse: () => SankalpType.BOOLEAN);
  }
}

/// Sankalp Template Model for admin management
class SankalpTemplate {
  SankalpTemplate({
    this.id,
    required this.title,
    this.titleHindi,
    required this.sankalpType,
    this.description,
    this.linkedContentTag,
    this.defaultTargetValue,
    this.defaultTargetUnit,
    this.defaultNotificationMessage,
    this.icon,
    this.isSystemTemplate = true,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory SankalpTemplate.fromJson(Map<String, dynamic> json) {
    return SankalpTemplate(
      id: json.getInt('id'),
      title: json.getString('title') ?? '',
      titleHindi: json.getString('titleHindi'),
      sankalpType: SankalpType.fromString(json.getString('sankalpType') ?? 'BOOLEAN'),
      description: json.getString('description'),
      linkedContentTag: json.getString('linkedContentTag'),
      defaultTargetValue: json.getInt('defaultTargetValue'),
      defaultTargetUnit: json.getString('defaultTargetUnit'),
      defaultNotificationMessage: json.getString('defaultNotificationMessage'),
      icon: json.getString('icon'),
      isSystemTemplate: json.getBool('isSystemTemplate', defaultValue: true),
      displayOrder: json.getInt('displayOrder') ?? 0,
      createdAt: json.getDateTime('createdAt'),
      updatedAt: json.getDateTime('updatedAt'),
    );
  }

  final int? id;
  final String title;
  final String? titleHindi;
  final SankalpType sankalpType;
  final String? description;
  final String? linkedContentTag;
  final int? defaultTargetValue;
  final String? defaultTargetUnit;
  final String? defaultNotificationMessage;
  final String? icon;
  final bool isSystemTemplate;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'titleHindi': titleHindi,
      'sankalpType': sankalpType.name,
      'description': description,
      'linkedContentTag': linkedContentTag,
      'defaultTargetValue': defaultTargetValue,
      'defaultTargetUnit': defaultTargetUnit,
      'defaultNotificationMessage': defaultNotificationMessage,
      'icon': icon,
      'isSystemTemplate': isSystemTemplate,
      'displayOrder': displayOrder,
    };
  }

  SankalpTemplate copyWith({
    int? id,
    String? title,
    String? titleHindi,
    SankalpType? sankalpType,
    String? description,
    String? linkedContentTag,
    int? defaultTargetValue,
    String? defaultTargetUnit,
    String? defaultNotificationMessage,
    String? icon,
    bool? isSystemTemplate,
    int? displayOrder,
  }) {
    return SankalpTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      titleHindi: titleHindi ?? this.titleHindi,
      sankalpType: sankalpType ?? this.sankalpType,
      description: description ?? this.description,
      linkedContentTag: linkedContentTag ?? this.linkedContentTag,
      defaultTargetValue: defaultTargetValue ?? this.defaultTargetValue,
      defaultTargetUnit: defaultTargetUnit ?? this.defaultTargetUnit,
      defaultNotificationMessage: defaultNotificationMessage ?? this.defaultNotificationMessage,
      icon: icon ?? this.icon,
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Common Material icons for sankalpas
class SankalpIcons {
  static const List<String> icons = [
    'self_improvement',
    'spa',
    'favorite',
    'psychology',
    'emoji_objects',
    'local_fire_department',
    'auto_awesome',
    'brightness_7',
    'wb_sunny',
    'nights_stay',
    'timer',
    'schedule',
    'event',
    'flag',
    'star',
    'favorite_border',
    'bookmark',
    'check_circle',
    'celebration',
    'music_note',
    'headphones',
    'menu_book',
    'library_books',
    'edit_note',
    'draw',
  ];

  static String getDisplayName(String icon) {
    return icon
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}
