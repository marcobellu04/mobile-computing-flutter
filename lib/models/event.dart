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
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      ownerEmail: map['ownerEmail'],
      ownerName: map['ownerName'] ?? '',
      ownerSurname: map['ownerSurname'] ?? '',
      maxParticipants: map['maxParticipants'],
      participants: List<String>.from(map['participants'] ?? []),
      pendingRequests: List<String>.from(map['pendingRequests'] ?? []),
      listType: ListType.values[map['listType']],
      venueId: map['venueId'],
      fullAddress: map['fullAddress'],
      ageRestrictionType: AgeRestrictionType.values[map['ageRestrictionType'] ?? 0],
      ageRestrictionValue: map['ageRestrictionValue'],
      zone: map['zone'],
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
    };
  }
}
