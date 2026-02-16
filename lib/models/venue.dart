class Venue {
  final String id;
  final String name;
  final int? capacity;
  final String? address;
  final String? email;
  final double lat;
  final double lng;
  final String? imagePath;

  Venue({
    required this.id,
    required this.name,
    this.capacity,
    this.address,
    this.email,
    required this.lat,
    required this.lng,
    this.imagePath,
  });

  factory Venue.fromMap(Map<String, dynamic> map) {
    return Venue(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      capacity: map['capacity'] as int?,
      address: map['address'] as String?,
      email: map['email'] as String?,
      imagePath: map['imagePath'] as String?,
      // Usiamo .toDouble() per sicurezza nel caso arrivino int da JSON
      lat: (map['lat'] as num?)?.toDouble() ?? 41.9028, 
      lng: (map['lng'] as num?)?.toDouble() ?? 12.4964,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'address': address,
      'email': email,
      'imagePath': imagePath,
      'lat': lat,
      'lng': lng,
    };
  }

  // Fondamentale per aggiornare i dati nel Provider
  Venue copyWith({
    String? id,
    String? name,
    int? capacity,
    String? address,
    String? email,
    double? lat,
    double? lng,
    String? imagePath,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      address: address ?? this.address,
      email: email ?? this.email,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}