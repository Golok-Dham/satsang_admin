/// Enhanced JSON utilities for type-safe serialization
class JsonUtils {
  /// Safely cast to String
  static String? asString(dynamic value) => value as String?;

  /// Safely cast to int
  static int? asInt(dynamic value) => value as int?;

  /// Safely cast to bool
  static bool asBool(dynamic value, {bool defaultValue = false}) =>
      value as bool? ?? defaultValue;

  /// Safely cast to double
  static double? asDouble(dynamic value) => value as double?;

  /// Safely cast to DateTime from string
  static DateTime? asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return null;
  }

  /// Safely cast to `List<T>`
  static List<T>? asList<T>(dynamic value, T Function(dynamic) mapper) {
    if (value == null) return null;
    if (value is List) return value.map(mapper).toList();
    return null;
  }

  /// Safely cast to `Map<String, dynamic>`
  static Map<String, dynamic>? asMap(dynamic value) =>
      value as Map<String, dynamic>?;
}

/// Extension methods for cleaner JSON handling
extension JsonExtensions on Map<String, dynamic> {
  String? getString(String key) => JsonUtils.asString(this[key]);
  int? getInt(String key) => JsonUtils.asInt(this[key]);
  bool getBool(String key, {bool defaultValue = false}) =>
      JsonUtils.asBool(this[key], defaultValue: defaultValue);
  double? getDouble(String key) => JsonUtils.asDouble(this[key]);
  DateTime? getDateTime(String key) => JsonUtils.asDateTime(this[key]);
  List<T>? getList<T>(String key, T Function(dynamic) mapper) =>
      JsonUtils.asList(this[key], mapper);
  Map<String, dynamic>? getMap(String key) => JsonUtils.asMap(this[key]);
}
