import '../../../core/utils/json_utils.dart';

/// Quiz question type enum matching backend QuestionType
// ignore: constant_identifier_names
enum QuestionType {
  // ignore: constant_identifier_names
  MULTIPLE_CHOICE,
  // ignore: constant_identifier_names
  TRUE_FALSE;

  String get displayName {
    switch (this) {
      case QuestionType.MULTIPLE_CHOICE:
        return 'Multiple Choice';
      case QuestionType.TRUE_FALSE:
        return 'True/False';
    }
  }
}

/// Quiz list item for admin listing (minimal data)
class QuizListItem {
  final int id;
  final int contentId;
  final String? contentTitle;
  final String? titleEn;
  final String? titleHi;
  final int questionCount;
  final bool isActive;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const QuizListItem({
    required this.id,
    required this.contentId,
    this.contentTitle,
    this.titleEn,
    this.titleHi,
    required this.questionCount,
    required this.isActive,
    required this.version,
    this.createdAt,
    this.updatedAt,
  });

  /// Get display title (prefer English, fallback to Hindi)
  String get displayTitle {
    if (titleEn != null && titleEn!.isNotEmpty) return titleEn!;
    if (titleHi != null && titleHi!.isNotEmpty) return titleHi!;
    return 'Quiz #$id';
  }

  factory QuizListItem.fromJson(Map<String, dynamic> json) {
    return QuizListItem(
      id: json['id'] as int,
      contentId: json['contentId'] as int,
      contentTitle: json['contentTitle'] as String?,
      titleEn: json['titleEn'] as String?,
      titleHi: json['titleHi'] as String?,
      questionCount: json['questionCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      version: json['version'] as int? ?? 1,
      createdAt: JsonUtils.parseDateTime(json['createdAt']),
      updatedAt: JsonUtils.parseDateTime(json['updatedAt']),
    );
  }

  QuizListItem copyWith({
    int? id,
    int? contentId,
    String? contentTitle,
    String? titleEn,
    String? titleHi,
    int? questionCount,
    bool? isActive,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuizListItem(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      contentTitle: contentTitle ?? this.contentTitle,
      titleEn: titleEn ?? this.titleEn,
      titleHi: titleHi ?? this.titleHi,
      questionCount: questionCount ?? this.questionCount,
      isActive: isActive ?? this.isActive,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Full quiz detail with questions for editing
class QuizDetail {
  final int id;
  final int contentId;
  final String? contentTitle;
  final String? titleEn;
  final String? titleHi;
  final String? descriptionEn;
  final String? descriptionHi;
  final bool isActive;
  final int version;
  final List<QuizQuestion> questions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const QuizDetail({
    required this.id,
    required this.contentId,
    this.contentTitle,
    this.titleEn,
    this.titleHi,
    this.descriptionEn,
    this.descriptionHi,
    required this.isActive,
    required this.version,
    required this.questions,
    this.createdAt,
    this.updatedAt,
  });

  factory QuizDetail.fromJson(Map<String, dynamic> json) {
    return QuizDetail(
      id: json['id'] as int,
      contentId: json['contentId'] as int,
      contentTitle: json['contentTitle'] as String?,
      titleEn: json['titleEn'] as String?,
      titleHi: json['titleHi'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      descriptionHi: json['descriptionHi'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      version: json['version'] as int? ?? 1,
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: JsonUtils.parseDateTime(json['createdAt']),
      updatedAt: JsonUtils.parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentId': contentId,
      'titleEn': titleEn,
      'titleHi': titleHi,
      'descriptionEn': descriptionEn,
      'descriptionHi': descriptionHi,
      'isActive': isActive,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

/// Quiz question model
class QuizQuestion {
  final int? id;
  final String? questionTextEn;
  final String? questionTextHi;
  final QuestionType questionType;
  final List<String> optionsEn;
  final List<String> optionsHi;
  final int correctAnswerIndex;
  final String? explanationEn;
  final String? explanationHi;
  final int displayOrder;
  final DateTime? createdAt;

  const QuizQuestion({
    this.id,
    this.questionTextEn,
    this.questionTextHi,
    required this.questionType,
    required this.optionsEn,
    required this.optionsHi,
    required this.correctAnswerIndex,
    this.explanationEn,
    this.explanationHi,
    required this.displayOrder,
    this.createdAt,
  });

  /// Get display question text (prefer English, fallback to Hindi)
  String get displayQuestionText {
    if (questionTextEn != null && questionTextEn!.isNotEmpty) {
      return questionTextEn!;
    }
    if (questionTextHi != null && questionTextHi!.isNotEmpty) {
      return questionTextHi!;
    }
    return 'Question ${displayOrder + 1}';
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    // Parse options from JSON string if needed
    List<String> parseOptions(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.cast<String>();
      if (value is String) {
        try {
          final decoded = JsonUtils.parseJsonList(value);
          return decoded.cast<String>();
        } catch (e) {
          return [];
        }
      }
      return [];
    }

    return QuizQuestion(
      id: json['id'] as int?,
      questionTextEn: json['questionTextEn'] as String?,
      questionTextHi: json['questionTextHi'] as String?,
      questionType: QuestionType.values.firstWhere(
        (e) => e.name == json['questionType'],
        orElse: () => QuestionType.MULTIPLE_CHOICE,
      ),
      optionsEn: parseOptions(json['optionsEn'] ?? json['optionsEnJson']),
      optionsHi: parseOptions(json['optionsHi'] ?? json['optionsHiJson']),
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
      explanationEn: json['explanationEn'] as String?,
      explanationHi: json['explanationHi'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      createdAt: JsonUtils.parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'questionTextEn': questionTextEn,
      'questionTextHi': questionTextHi,
      'questionType': questionType.name,
      'optionsEn': optionsEn,
      'optionsHi': optionsHi,
      'correctAnswerIndex': correctAnswerIndex,
      'explanationEn': explanationEn,
      'explanationHi': explanationHi,
      'displayOrder': displayOrder,
    };
  }

  QuizQuestion copyWith({
    int? id,
    String? questionTextEn,
    String? questionTextHi,
    QuestionType? questionType,
    List<String>? optionsEn,
    List<String>? optionsHi,
    int? correctAnswerIndex,
    String? explanationEn,
    String? explanationHi,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      questionTextEn: questionTextEn ?? this.questionTextEn,
      questionTextHi: questionTextHi ?? this.questionTextHi,
      questionType: questionType ?? this.questionType,
      optionsEn: optionsEn ?? this.optionsEn,
      optionsHi: optionsHi ?? this.optionsHi,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      explanationEn: explanationEn ?? this.explanationEn,
      explanationHi: explanationHi ?? this.explanationHi,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Create a new empty question
  factory QuizQuestion.empty({int displayOrder = 0}) {
    return QuizQuestion(
      questionType: QuestionType.MULTIPLE_CHOICE,
      optionsEn: ['', '', '', ''],
      optionsHi: [],
      correctAnswerIndex: 0,
      displayOrder: displayOrder,
    );
  }

  /// Create a true/false question
  factory QuizQuestion.trueFalse({int displayOrder = 0}) {
    return QuizQuestion(
      questionType: QuestionType.TRUE_FALSE,
      optionsEn: ['True', 'False'],
      optionsHi: ['सत्य', 'असत्य'],
      correctAnswerIndex: 0,
      displayOrder: displayOrder,
    );
  }
}
