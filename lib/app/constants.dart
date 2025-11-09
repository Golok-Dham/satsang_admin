/// Application-wide constants and configuration
class AppConstants {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String apiBaseUrlProd = 'https://api.satsang.golokdham.in';
  static const String apiBaseUrlUat = 'https://test-api.satsang.golokdham.in';

  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';
  static bool get isUat => environment == 'uat';
  static bool get isDevelopment => environment == 'development';

  // API Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // App Info
  static const String appName = 'Satsang Admin';
  static const String appVersion = '1.0.0';

  // Firebase Collections (if needed for Firestore)
  static const String usersCollection = 'users';
  static const String sessionsCollection = 'sessions';

  // Storage
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
}
