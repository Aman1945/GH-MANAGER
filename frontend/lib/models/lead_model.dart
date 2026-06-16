import 'guest_house_model.dart';

class LeadModel {
  final String id;
  final String guestName;
  final String phone;
  final String email;
  final DateTime checkIn;
  final DateTime checkOut;
  final GuestHouseModel? preferredGuestHouse;
  final String status;
  final DateTime createdAt;

  const LeadModel({
    required this.id,
    required this.guestName,
    required this.phone,
    required this.email,
    required this.checkIn,
    required this.checkOut,
    this.preferredGuestHouse,
    required this.status,
    required this.createdAt,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    GuestHouseModel? gh;
    final ghRaw = json['preferredGuestHouseId'];
    if (ghRaw is Map<String, dynamic>) {
      gh = GuestHouseModel.fromJson(ghRaw);
    }

    return LeadModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      guestName: json['guestName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      checkIn: DateTime.tryParse(json['checkIn']?.toString() ?? '') ??
          DateTime.now(),
      checkOut: DateTime.tryParse(json['checkOut']?.toString() ?? '') ??
          DateTime.now(),
      preferredGuestHouse: gh,
      status: json['status']?.toString() ?? 'PENDING',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'guestName': guestName,
        'phone': phone,
        'email': email,
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}
