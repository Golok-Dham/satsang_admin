import '../../../core/utils/json_utils.dart';

/// Content Translation model
class ContentTranslation {
  ContentTranslation({
    this.id,
    required this.contentId,
    required this.languageCode,
    required this.title,
    this.description,
  });

  factory ContentTranslation.fromJson(Map<String, dynamic> json) {
    return ContentTranslation(
      id: json.getInt('id'),
      contentId: json.getInt('contentId')!,
      languageCode: json.getString('languageCode')!,
      title: json.getString('title')!,
      description: json.getString('description'),
    );
  }

  final int? id;
  final int contentId;
  final String languageCode;
  final String title;
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'contentId': contentId,
      'languageCode': languageCode,
      'title': title,
      'description': description,
    };
  }
}
