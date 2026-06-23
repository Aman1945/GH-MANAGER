import 'room_model.dart';
import 'guest_house_model.dart';

class MaintenanceModel {
  final String id;
  final RoomModel? room;
  final String? bookingId;
  final String? guestName;
  final GuestHouseModel? guestHouse;
  final String description;
  final String? reportedBy;
  final String status;
  final DateTime createdAt;

  const MaintenanceModel({
    required this.id,
    this.room,
    this.bookingId,
    this.guestName,
    this.guestHouse,
    required this.description,
    this.reportedBy,
    required this.status,
    required this.createdAt,
  });

  factory MaintenanceModel.fromJson(Map<String, dynamic> json) {
    RoomModel? r;
    if (json['roomId'] is Map<String, dynamic>) {
      r = RoomModel.fromJson(json['roomId'] as Map<String, dynamic>);
    }

    GuestHouseModel? gh;
    if (json['guestHouseId'] is Map<String, dynamic>) {
      gh = GuestHouseModel.fromJson(json['guestHouseId'] as Map<String, dynamic>);
    }

    String? gName;
    String? bId;
    if (json['bookingId'] is Map<String, dynamic>) {
      final bMap = json['bookingId'] as Map<String, dynamic>;
      bId = bMap['_id']?.toString() ?? bMap['id']?.toString();
      gName = bMap['guestName']?.toString();
    } else if (json['bookingId'] is String) {
      bId = json['bookingId'] as String;
    }

    String? reporter;
    if (json['reportedBy'] is Map<String, dynamic>) {
      reporter = (json['reportedBy'] as Map<String, dynamic>)['name']?.toString();
    } else if (json['reportedBy'] is String) {
      reporter = json['reportedBy'] as String;
    }

    return MaintenanceModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      room: r,
      bookingId: bId,
      guestName: gName,
      guestHouse: gh,
      description: json['description']?.toString() ?? '',
      reportedBy: reporter,
      status: json['status']?.toString() ?? 'OPEN',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}
