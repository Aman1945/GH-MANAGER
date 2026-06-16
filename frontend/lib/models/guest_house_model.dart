class GuestHouseModel {
  final String id;
  final String name;
  final String? location;

  const GuestHouseModel({
    required this.id,
    required this.name,
    this.location,
  });

  factory GuestHouseModel.fromJson(Map<String, dynamic> json) {
    return GuestHouseModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        if (location != null) 'location': location,
      };
}
