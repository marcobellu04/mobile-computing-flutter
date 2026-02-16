import 'package:cloud_firestore/cloud_firestore.dart';

enum ListType { open, closed }
enum AgeRestrictionType { none, under, over }

class Event {
  final String id;
  final String name;
  final String? description;
  final DateTime date;
  final String ownerEmail;
  final String ownerName;
  final String ownerSurname;
  final int maxParticipants;
  final List<String> participants;
  final List<String> pendingRequests;
  final ListType listType;
  final String? venueId;
  final String? fullAddress;
  final AgeRestrictionType ageRestrictionType;
  final int? ageRestrictionValue;
  final String? zone;
  final double? lat; 
  final double? lng; 
  final String? imagePath; // <--- AGGIUNTO

  Event({
    required this.id,
    required this.name,
    this.description,
    required this.date,
    required this.ownerEmail,
    required this.ownerName,
    required this.ownerSurname,
    required this.maxParticipants,
    this.participants = const [],
    this.pendingRequests = const [],
    required this.listType,
    this.venueId,
    this.fullAddress,
    this.ageRestrictionType = AgeRestrictionType.none,
    this.ageRestrictionValue,
    this.zone,
    this.lat,         
    this.lng,
    this.imagePath, // <--- AGGIUNTO
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    // Gestione flessibile della data per SharedPreferences e Firestore
    DateTime parsedDate;
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      parsedDate = DateTime.parse(map['date']);
    } else {
      parsedDate = DateTime.now();
    }

    return Event(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      date: parsedDate,
      ownerEmail: map['ownerEmail'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerSurname: map['ownerSurname'] ?? '',
      maxParticipants: map['maxParticipants'] ?? 0,
      participants: List<String>.from(map['participants'] ?? []),
      pendingRequests: List<String>.from(map['pendingRequests'] ?? []),
      listType: ListType.values[map['listType'] ?? 0],
      venueId: map['venueId'],
      fullAddress: map['fullAddress'],
      ageRestrictionType: AgeRestrictionType.values[map['ageRestrictionType'] ?? 0],
      ageRestrictionValue: map['ageRestrictionValue'],
      zone: map['zone'],
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      imagePath: map['imagePath'], // <--- AGGIUNTO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String(), 
      'ownerEmail': ownerEmail,
      'ownerName': ownerName,
      'ownerSurname': ownerSurname,
      'maxParticipants': maxParticipants,
      'participants': participants,
      'pendingRequests': pendingRequests,
      'listType': listType.index,
      'venueId': venueId,
      'fullAddress': fullAddress,
      'ageRestrictionType': ageRestrictionType.index,
      'ageRestrictionValue': ageRestrictionValue,
      'zone': zone,
      'lat': lat,
      'lng': lng,
      'imagePath': imagePath, // <--- AGGIUNTO
    };
  }

  Event copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? date,
    String? ownerEmail,
    String? ownerName,
    String? ownerSurname,
    int? maxParticipants,
    List<String>? participants,
    List<String>? pendingRequests,
    ListType? listType,
    String? venueId,
    String? fullAddress,
    AgeRestrictionType? ageRestrictionType,
    int? ageRestrictionValue,
    String? zone,
    double? lat,
    double? lng,
    String? imagePath, // <--- AGGIUNTO
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerName: ownerName ?? this.ownerName,
      ownerSurname: ownerSurname ?? this.ownerSurname,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants ?? this.participants,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      listType: listType ?? this.listType,
      venueId: venueId ?? this.venueId,
      fullAddress: fullAddress ?? this.fullAddress,
      ageRestrictionType: ageRestrictionType ?? this.ageRestrictionType,
      ageRestrictionValue: ageRestrictionValue ?? this.ageRestrictionValue,
      zone: zone ?? this.zone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imagePath: imagePath ?? this.imagePath, // <--- AGGIUNTO
    );
  }
}