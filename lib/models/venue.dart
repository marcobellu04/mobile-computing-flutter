class Venue {
  final String id;
  final String name;
  final int? capacity;
  final String? address;
  final String? phone;
  final String? description;
  final String ownerEmail;
  final String ownerName;    // AGGIUNTO
  final String ownerSurname; // AGGIUNTO
  final double lat;
  final double lng;
  final String? imagePath;

  Venue({
    required this.id,
    required this.name,
    required this.ownerEmail,
    required this.ownerName,    // AGGIUNTO
    required this.ownerSurname, // AGGIUNTO
    this.capacity,
    this.address,
    this.phone,
    this.description,
    required this.lat,
    required this.lng,
    this.imagePath,
  });

  factory Venue.fromMap(Map<String, dynamic> map) {
    return Venue(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      ownerEmail: map['ownerEmail']?.toString() ?? 'unknown',
      ownerName: map['ownerName'] ?? '',       // AGGIUNTO
      ownerSurname: map['ownerSurname'] ?? '', // AGGIUNTO
      capacity: map['capacity'] as int?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      description: map['description'] as String?,
      imagePath: map['imagePath'] as String?,
      lat: (map['lat'] as num?)?.toDouble() ?? 41.9028,
      lng: (map['lng'] as num?)?.toDouble() ?? 12.4964,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerEmail': ownerEmail,
      'ownerName': ownerName,       // AGGIUNTO
      'ownerSurname': ownerSurname, // AGGIUNTO
      'capacity': capacity,
      'address': address,
      'phone': phone,
      'description': description,
      'imagePath': imagePath,
      'lat': lat,
      'lng': lng,
    };
  }

  Venue copyWith({
    String? id,
    String? name,
    String? ownerEmail,
    String? ownerName,
    String? ownerSurname,
    int? capacity,
    String? address,
    String? phone,
    String? description,
    double? lat,
    double? lng,
    String? imagePath,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerName: ownerName ?? this.ownerName,
      ownerSurname: ownerSurname ?? this.ownerSurname,
      capacity: capacity ?? this.capacity,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}