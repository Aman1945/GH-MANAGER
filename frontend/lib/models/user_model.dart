class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? guestHouseId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.guestHouseId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? ghId;
    final ghRaw = json['guestHouseId'];
    if (ghRaw is Map) {
      ghId = ghRaw['_id']?.toString() ?? ghRaw['id']?.toString();
    } else if (ghRaw is String) {
      ghId = ghRaw;
    }

    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      guestHouseId: ghId,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'role': role,
        if (guestHouseId != null) 'guestHouseId': guestHouseId,
      };
}
