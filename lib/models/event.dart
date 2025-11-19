enum ListType { open, closed }
enum AgeRestrictionType { none, under, over }

class Event {
  final String id;
  final String name;
  final String? description;
  final DateTime date;
  final String? zone; // zona libera
  final String? fullAddress;
  final String ownerEmail;
  final int maxParticipants;
  final AgeRestrictionType ageRestrictionType; // nuovo tipo età
  final int? ageRestrictionValue; // valore età (es. 30)
  final List<String> participants;
  final List<String> pendingRequests;
  final ListType listType;
  final String? venueId;

  Event({
    required this.id,
    required this.name,
    this.description,
    required this.date,
    this.zone,
    this.fullAddress,
    required this.ownerEmail,
    required this.maxParticipants,
    this.ageRestrictionType = AgeRestrictionType.none,
    this.ageRestrictionValue,
    List<String>? participants,
    List<String>? pendingRequests,
    required this.listType,
    this.venueId,
  })  : participants = participants ?? [],
        pendingRequests = pendingRequests ?? [];

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      zone: map['zone'] as String?,
      fullAddress: map['fullAddress'] as String?,
      ownerEmail: map['ownerEmail'] as String,
      maxParticipants: map['maxParticipants'] as int,
      ageRestrictionType: map.containsKey('ageRestrictionType')
          ? AgeRestrictionType.values[map['ageRestrictionType'] as int]
          : AgeRestrictionType.none,
      ageRestrictionValue: map['ageRestrictionValue'] as int?,
      participants: List<String>.from(map['participants'] ?? []),
      pendingRequests: List<String>.from(map['pendingRequests'] ?? []),
      listType: ListType.values[map['listType'] as int],
      venueId: map['venueId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'zone': zone,
      'fullAddress': fullAddress,
      'ownerEmail': ownerEmail,
      'maxParticipants': maxParticipants,
      'ageRestrictionType': ageRestrictionType.index,
      'ageRestrictionValue': ageRestrictionValue,
      'participants': participants,
      'pendingRequests': pendingRequests,
      'listType': listType.index,
      'venueId': venueId,
    };
  }
}
