class BookingModel {
  final String id;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final String bookingStatus;
  final String paymentStatus;
  final String? roomNumber;
  final String? guestHouseName;
  final String? approvedByName;

  const BookingModel({
    required this.id,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.bookingStatus,
    required this.paymentStatus,
    this.roomNumber,
    this.guestHouseName,
    this.approvedByName,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    String? roomNum;
    final roomRaw = json['roomId'];
    if (roomRaw is Map) {
      roomNum = roomRaw['roomNumber']?.toString();
    } else if (roomRaw is String) {
      roomNum = roomRaw;
    }

    String? ghName;
    final ghRaw = json['guestHouseId'];
    if (ghRaw is Map) {
      ghName = ghRaw['name']?.toString();
    }

    String? approvedBy;
    final abRaw = json['approvedBy'];
    if (abRaw is Map) {
      approvedBy = abRaw['name']?.toString();
    }

    return BookingModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      guestName: json['guestName']?.toString() ?? '',
      checkIn: DateTime.tryParse(json['checkIn']?.toString() ?? '') ??
          DateTime.now(),
      checkOut: DateTime.tryParse(json['checkOut']?.toString() ?? '') ??
          DateTime.now(),
      bookingStatus: json['bookingStatus']?.toString() ?? 'CONFIRMED',
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      roomNumber: roomNum,
      guestHouseName: ghName,
      approvedByName: approvedBy,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'guestName': guestName,
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
        'bookingStatus': bookingStatus,
        'paymentStatus': paymentStatus,
        if (roomNumber != null) 'roomNumber': roomNumber,
        if (guestHouseName != null) 'guestHouseName': guestHouseName,
        if (approvedByName != null) 'approvedByName': approvedByName,
      };
}
