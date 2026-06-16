import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lead_model.dart';
import '../services/api_service.dart';

class LeadsNotifier extends StateNotifier<AsyncValue<List<LeadModel>>> {
  LeadsNotifier() : super(const AsyncValue.loading()) {
    fetchLeads();
  }

  final ApiService _api = ApiService();

  Future<void> fetchLeads() async {
    state = const AsyncValue.loading();
    try {
      final raw = await _api.getLeads();
      final leads = raw
          .map((e) => LeadModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(leads);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createLead(Map<String, dynamic> data) async {
    try {
      await _api.createLead(data);
      await fetchLeads();
    } catch (e) {
      rethrow;
    }
  }
}

final leadsProvider =
    StateNotifierProvider<LeadsNotifier, AsyncValue<List<LeadModel>>>(
  (ref) => LeadsNotifier(),
);
