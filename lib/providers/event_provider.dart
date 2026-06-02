import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventProvider extends ChangeNotifier {
  List<Event> _events = [];

  List<Event> get events {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _events.where((e) {
      return e.date.isAfter(today) || e.date.isAtSameMomentAs(today);
    }).toList();
  }

  EventProvider() {
    loadEvents();
  }

 void loadEvents() {
  FirebaseFirestore.instance
      .collection('events')
      .snapshots()
      .listen((snapshot) {
    _events = snapshot.docs
        .map((doc) => Event.fromMap(doc.data()))
        .toList();

    notifyListeners();
  });
}

  Future<void> addEvent(Event event) async {
  try {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(event.id)
        .set(event.toMap());
  } catch (e) {
    debugPrint("Errore salvataggio evento su Firestore: $e");
  }
}

  Future<void> joinEvent(String eventId, String email) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final event = _events[index];
    if (event.participants.contains(email)) return;

    final updatedEvent = event.copyWith(
      participants: [...event.participants, email],
    );

    _events[index] = updatedEvent;

    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .set(updatedEvent.toMap());

    notifyListeners();
  }

  Future<void> requestToJoin(String eventId, String email) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final event = _events[index];

    if (event.pendingRequests.contains(email) ||
        event.participants.contains(email)) {
      return;
    }

    final updatedEvent = event.copyWith(
      pendingRequests: [...event.pendingRequests, email],
    );

    _events[index] = updatedEvent;

    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .set(updatedEvent.toMap());

    notifyListeners();
  }

  Future<void> approveRequest(String eventId, String userEmail) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final event = _events[index];

    final updatedEvent = event.copyWith(
      pendingRequests:
          event.pendingRequests.where((e) => e != userEmail).toList(),
      participants: [...event.participants, userEmail],
    );

    _events[index] = updatedEvent;

    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .set(updatedEvent.toMap());

    notifyListeners();
  }

  Future<void> rejectRequest(String eventId, String userEmail) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final event = _events[index];

    final updatedEvent = event.copyWith(
      pendingRequests:
          event.pendingRequests.where((e) => e != userEmail).toList(),
    );

    _events[index] = updatedEvent;

    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .set(updatedEvent.toMap());

    notifyListeners();
  }

  Future<void> deleteEvent(String eventId) async {
    _events.removeWhere((e) => e.id == eventId);

    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .delete();

    notifyListeners();
  }

  Future<void> deleteEventsByOwner(String ownerEmail) async {
    final toDelete = _events
        .where((e) =>
            e.ownerEmail.trim().toLowerCase() ==
            ownerEmail.trim().toLowerCase())
        .toList();

    for (final event in toDelete) {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .delete();
    }

    _events.removeWhere((e) =>
        e.ownerEmail.trim().toLowerCase() ==
        ownerEmail.trim().toLowerCase());

    notifyListeners();
  }

  List<Event> getUpcomingParticipations(String email) {
    if (email.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _events
        .where((e) =>
            e.participants.contains(email) &&
            (e.date.isAfter(today) || e.date.isAtSameMomentAs(today)))
        .toList();
  }

  Future<void> updateEvent(Event updatedEvent) async {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);

    if (index != -1) {
      _events[index] = updatedEvent;

      await FirebaseFirestore.instance
          .collection('events')
          .doc(updatedEvent.id)
          .set(updatedEvent.toMap());

      notifyListeners();
    }
  }

  int getTotalPendingRequestsForOwner(String ownerEmail) {
    return _events
        .where((e) =>
            e.ownerEmail.trim().toLowerCase() ==
            ownerEmail.trim().toLowerCase())
        .fold(0, (sum, event) => sum + event.pendingRequests.length);
  }

  bool hasNotifications(String ownerEmail) {
    return getTotalPendingRequestsForOwner(ownerEmail) > 0;
  }

  int countPendingRequestsForOwner(String ownerEmail) {
    return _events
        .where((e) =>
            e.ownerEmail.trim().toLowerCase() ==
            ownerEmail.trim().toLowerCase())
        .fold(0, (sum, event) => sum + event.pendingRequests.length);
  }
}