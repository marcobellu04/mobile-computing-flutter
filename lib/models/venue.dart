class Venue {
  final String id;
  final String name;
  final int? capacity;
  final String? address;
  final String? email;
  // se hai altri campi, aggiungili qui (es. imagePath)

  Venue({
    required this.id,
    required this.name,
    this.capacity,
    this.address,
    this.email,
  });

  factory Venue.fromMap(Map<String, dynamic> map) {
    return Venue(
      id: map['id'] as String,
      name: map['name'] as String,
      capacity: map['capacity'] != null ? map['capacity'] as int : null,
      address: map['address'] as String?,
      email: map['email'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'address': address,
      'email': email,
    };
  }
}

