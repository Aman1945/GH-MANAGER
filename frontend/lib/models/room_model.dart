import 'guest_house_model.dart';

class RoomModel {
  final String id;
  final String roomNumber;
  final String status;
  final GuestHouseModel? guestHouse;

  const RoomModel({
    required this.id,
    required this.roomNumber,
    required this.status,
    this.guestHouse,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    GuestHouseModel? gh;
    final ghRaw = json['guestHouseId'];
    if (ghRaw is Map<String, dynamic>) {
      gh = GuestHouseModel.fromJson(ghRaw);
    }

    return RoomModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      roomNumber: json['roomNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? 'AVAILABLE',
      guestHouse: gh,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'roomNumber': roomNumber,
        'status': status,
        if (guestHouse != null) 'guestHouseId': guestHouse!.toJson(),
      };
}
