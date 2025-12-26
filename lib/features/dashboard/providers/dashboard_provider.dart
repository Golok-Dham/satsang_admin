import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/api_service.dart';

part 'dashboard_provider.g.dart';

/// Dashboard statistics model
class DashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int premiumUsers;
  final int activeSessions;
  final int activeSessionUsers;
  final int totalContent;
  final int videoCount;
  final int audioCount;
  final int totalPlaylists;
  final int totalQuotes;
  final int totalQuizzes;
  final int totalSankalpTemplates;
  final DateTime timestamp;

  DashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.premiumUsers,
    required this.activeSessions,
    required this.activeSessionUsers,
    required this.totalContent,
    required this.videoCount,
    required this.audioCount,
    required this.totalPlaylists,
    required this.totalQuotes,
    required this.totalQuizzes,
    required this.totalSankalpTemplates,
    required this.timestamp,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      premiumUsers: json['premiumUsers'] ?? 0,
      activeSessions: json['activeSessions'] ?? 0,
      activeSessionUsers: json['activeSessionUsers'] ?? 0,
      totalContent: json['totalContent'] ?? 0,
      videoCount: json['videoCount'] ?? 0,
      audioCount: json['audioCount'] ?? 0,
      totalPlaylists: json['totalPlaylists'] ?? 0,
      totalQuotes: json['totalQuotes'] ?? 0,
      totalQuizzes: json['totalQuizzes'] ?? 0,
      totalSankalpTemplates: json['totalSankalpTemplates'] ?? 0,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }
}

/// Provider for fetching dashboard statistics
@riverpod
Future<DashboardStats> dashboardStats(Ref ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.dio.get('/api/admin/dashboard/stats');

  final data = response.data as Map<String, dynamic>;
  if (data['success'] == true && data['data'] != null) {
    return DashboardStats.fromJson(data['data']);
  }

  throw Exception(data['message'] ?? 'Failed to load dashboard stats');
}
