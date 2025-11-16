/// Model for a single karaoke line with timestamps
class KaraokeLine {
  final int index;
  final double startTime;
  final double endTime;
  final String hindi;
  final String english;
  final String hindiMeaning;
  final String englishMeaning;

  KaraokeLine({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.hindi,
    required this.english,
    this.hindiMeaning = '',
    this.englishMeaning = '',
  });

  factory KaraokeLine.fromJson(Map<String, dynamic> json) {
    return KaraokeLine(
      index: json['index'] as int,
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
      hindi: json['hindi'] as String? ?? '',
      english: json['english'] as String? ?? '',
      hindiMeaning: json['hindiMeaning'] as String? ?? '',
      englishMeaning: json['englishMeaning'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'startTime': startTime,
      'endTime': endTime,
      'hindi': hindi,
      'english': english,
      'hindiMeaning': hindiMeaning,
      'englishMeaning': englishMeaning,
    };
  }

  KaraokeLine copyWith({
    int? index,
    double? startTime,
    double? endTime,
    String? hindi,
    String? english,
    String? hindiMeaning,
    String? englishMeaning,
  }) {
    return KaraokeLine(
      index: index ?? this.index,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hindi: hindi ?? this.hindi,
      english: english ?? this.english,
      hindiMeaning: hindiMeaning ?? this.hindiMeaning,
      englishMeaning: englishMeaning ?? this.englishMeaning,
    );
  }

  /// Validates this line
  String? validate() {
    if (startTime < 0) return 'Start time cannot be negative';
    if (endTime <= startTime) return 'End time must be greater than start time';
    if (hindi.trim().isEmpty && english.trim().isEmpty) {
      return 'At least one language text is required';
    }
    return null;
  }

  /// Duration of this line in seconds
  double get duration => endTime - startTime;
}

/// Model for karaoke metadata
class KaraokeMetadata {
  final int duration;
  final String language;
  final String tempo;
  final String createdBy;
  final DateTime lastUpdated;

  KaraokeMetadata({
    required this.duration,
    required this.language,
    required this.tempo,
    required this.createdBy,
    required this.lastUpdated,
  });

  factory KaraokeMetadata.fromJson(Map<String, dynamic> json) {
    return KaraokeMetadata(
      duration: json['duration'] as int,
      language: json['language'] as String? ?? 'hindi',
      tempo: json['tempo'] as String? ?? 'medium',
      createdBy: json['created_by'] as String? ?? 'admin',
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'language': language,
      'tempo': tempo,
      'created_by': createdBy,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  KaraokeMetadata copyWith({int? duration, String? language, String? tempo, String? createdBy, DateTime? lastUpdated}) {
    return KaraokeMetadata(
      duration: duration ?? this.duration,
      language: language ?? this.language,
      tempo: tempo ?? this.tempo,
      createdBy: createdBy ?? this.createdBy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Complete karaoke data structure
class KaraokeData {
  final List<KaraokeLine> lines;
  final KaraokeMetadata metadata;

  KaraokeData({required this.lines, required this.metadata});

  factory KaraokeData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> linesJson = json['lines'] as List<dynamic>;
    final lines = linesJson.map((line) => KaraokeLine.fromJson(line as Map<String, dynamic>)).toList();

    final metadata = KaraokeMetadata.fromJson(json['metadata'] as Map<String, dynamic>);

    return KaraokeData(lines: lines, metadata: metadata);
  }

  Map<String, dynamic> toJson() {
    return {'lines': lines.map((line) => line.toJson()).toList(), 'metadata': metadata.toJson()};
  }

  /// Validates all lines
  List<String> validate() {
    final errors = <String>[];

    if (lines.isEmpty) {
      errors.add('At least one line is required');
      return errors;
    }

    // Check index sequence
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].index != i) {
        errors.add('Line ${lines[i].index}: Index mismatch (expected $i)');
      }

      // Validate individual line
      final lineError = lines[i].validate();
      if (lineError != null) {
        errors.add('Line ${lines[i].index}: $lineError');
      }

      // Check time sequence with next line
      if (i < lines.length - 1) {
        if (lines[i].endTime > lines[i + 1].startTime) {
          errors.add(
            'Line ${lines[i].index}: Overlaps with next line '
            '(${lines[i].endTime} > ${lines[i + 1].startTime})',
          );
        }
      }
    }

    return errors;
  }

  /// Creates empty karaoke data
  factory KaraokeData.empty() {
    return KaraokeData(
      lines: [],
      metadata: KaraokeMetadata(
        duration: 0,
        language: 'hindi',
        tempo: 'medium',
        createdBy: 'admin',
        lastUpdated: DateTime.now(),
      ),
    );
  }
}
