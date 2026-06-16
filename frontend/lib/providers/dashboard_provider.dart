import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final adminDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ApiService().getAdminDashboard();
});

final bmDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ApiService().getBMDashboard();
});

final ghmDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ApiService().getGHMDashboard();
});
