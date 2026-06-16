import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room_model.dart';
import '../models/guest_house_model.dart';
import '../services/api_service.dart';

class RoomsNotifier extends StateNotifier<AsyncValue<List<RoomModel>>> {
  RoomsNotifier() : super(const AsyncValue.loading()) {
    fetchRooms();
  }

  final ApiService _api = ApiService();

  Future<void> fetchRooms({String? guestHouseId}) async {
    state = const AsyncValue.loading();
    try {
      final raw = await _api.getRooms(guestHouseId: guestHouseId);
      final rooms = raw
          .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(rooms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final roomsProvider =
    StateNotifierProvider<RoomsNotifier, AsyncValue<List<RoomModel>>>(
  (ref) => RoomsNotifier(),
);

final guestHousesProvider = FutureProvider<List<GuestHouseModel>>((ref) async {
  final raw = await ApiService().getRooms();
  final rooms =
      raw.map((e) => RoomModel.fromJson(e as Map<String, dynamic>)).toList();

  final seen = <String>{};
  final guestHouses = <GuestHouseModel>[];
  for (final room in rooms) {
    if (room.guestHouse != null && seen.add(room.guestHouse!.id)) {
      guestHouses.add(room.guestHouse!);
    }
  }
  return guestHouses;
});
