import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/maintenance_model.dart';
import '../services/api_service.dart';

class MaintenanceNotifier extends StateNotifier<AsyncValue<List<MaintenanceModel>>> {
  MaintenanceNotifier() : super(const AsyncValue.loading()) {
    fetchRequests();
  }

  final ApiService _api = ApiService();

  Future<void> fetchRequests() async {
    state = const AsyncValue.loading();
    try {
      final raw = await _api.getMaintenanceRequests();
      final list = raw
          .map((e) => MaintenanceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createRequest(Map<String, dynamic> data) async {
    try {
      await _api.createMaintenanceRequest(data);
      await fetchRequests();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resolveRequest(String id) async {
    try {
      await _api.resolveMaintenanceRequest(id);
      await fetchRequests();
    } catch (e) {
      rethrow;
    }
  }
}

final maintenanceProvider =
    StateNotifierProvider<MaintenanceNotifier, AsyncValue<List<MaintenanceModel>>>(
  (ref) => MaintenanceNotifier(),
);
