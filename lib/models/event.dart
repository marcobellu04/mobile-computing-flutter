import 'venue.dart';

enum ListType { open, closed }

class Event {
  final String name;
  final DateTime date;
  final int people;
  final int maxParticipants;
  final String description;
  final String zone;
  final ListType listType;
  final Venue? venue;
  final List<String> participants;
  final List<String> pendingRequests;
  final String ownerEmail;
  final int? ageRestriction;

  Event({
    required this.name,
    required this.date,
    required this.people,
    required this.maxParticipants,
    required this.description,
    required this.zone,
    required this.listType,
    this.venue,
    required this.participants,
    required this.pendingRequests,
    required this.ownerEmail,
    this.ageRestriction,
  });

  // Getter per indirizzo completo
  String? get fullAddress => venue?.address;
}
