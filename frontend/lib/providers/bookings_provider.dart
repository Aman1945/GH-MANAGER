import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';

class BookingsNotifier extends StateNotifier<AsyncValue<List<BookingModel>>> {
  BookingsNotifier() : super(const AsyncValue.loading()) {
    fetchBookings();
  }

  final ApiService _api = ApiService();

  Future<void> fetchBookings() async {
    state = const AsyncValue.loading();
    try {
      final raw = await _api.getBookings();
      final bookings = raw
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(bookings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markPayment(String bookingId) async {
    try {
      await _api.markPayment(bookingId);
      await fetchBookings();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkout(String bookingId) async {
    try {
      await _api.checkout(bookingId);
      await fetchBookings();
    } catch (e) {
      rethrow;
    }
  }
}

final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, AsyncValue<List<BookingModel>>>(
  (ref) => BookingsNotifier(),
);
