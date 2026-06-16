import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lead_model.dart';
import '../services/api_service.dart';

class ApprovalsNotifier extends StateNotifier<AsyncValue<List<LeadModel>>> {
  ApprovalsNotifier() : super(const AsyncValue.loading()) {
    fetchPending();
  }

  final ApiService _api = ApiService();

  Future<void> fetchPending() async {
    state = const AsyncValue.loading();
    try {
      final raw = await _api.getPendingApprovals();
      final leads = raw
          .map((e) => LeadModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(leads);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> approveLead(String leadId, String roomId) async {
    try {
      await _api.approveLead(leadId, roomId);
      await fetchPending();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectLead(String leadId) async {
    try {
      await _api.rejectLead(leadId);
      await fetchPending();
    } catch (e) {
      rethrow;
    }
  }
}

final approvalsProvider =
    StateNotifierProvider<ApprovalsNotifier, AsyncValue<List<LeadModel>>>(
  (ref) => ApprovalsNotifier(),
);
