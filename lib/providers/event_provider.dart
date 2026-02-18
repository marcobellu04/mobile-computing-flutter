import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';

class EventProvider extends ChangeNotifier {
  List<Event> _events = [];

  List<Event> get events => _events;

  EventProvider() {
    loadEvents();
  }

  // ─────────────────────────────
  // LOAD / SAVE
  // ─────────────────────────────

  Future<void> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('events');
    if (data != null) {
      try {
        final List list = jsonDecode(data);
        _events = list.map((e) => Event.fromMap(e as Map<String, dynamic>)).toList();
        notifyListeners();
      } catch (e) {
        print("Errore nel caricamento eventi: $e");
      }
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _events.map((e) => e.toMap()).toList();
    await prefs.setString('events', jsonEncode(list));
  }

  // ─────────────────────────────
  // BASIC CRUD
  // ─────────────────────────────

  void addEvent(Event event) {
    _events.add(event);
    _saveEvents();
    notifyListeners();
  }

  void updateEvent(Event updatedEvent) {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      // ✅ Verifica che l'evento aggiornato mantenga le coordinate
      if (updatedEvent.lat == null || updatedEvent.lng == null) {
        print("ALERT: Tentativo di aggiornamento evento con coordinate NULL");
      }
      _events[index] = updatedEvent;
      _saveEvents();
      notifyListeners();
    }
  }

  void updateEventImage(String eventId, String newPath) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _events[index] = _events[index].copyWith(imagePath: newPath);
      _saveEvents();
      notifyListeners();
    }
  }

  // ─────────────────────────────
  // PARTECIPAZIONE (Con controlli log)
  // ─────────────────────────────

  void joinEvent(String eventId, String email) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    
    final event = _events[index];
   final updated = Event(
    id: event.id,
    name: event.name,
    description: event.description,
    date: event.date,
    ownerEmail: event.ownerEmail,
    ownerName: event.ownerName,
    ownerSurname: event.ownerSurname,
    maxParticipants: event.maxParticipants,
    participants: [...event.participants, email], // Aggiungiamo solo questo
    pendingRequests: event.pendingRequests,
    listType: event.listType,
    venueId: event.venueId,
    fullAddress: event.fullAddress,
    ageRestrictionType: event.ageRestrictionType,
    ageRestrictionValue: event.ageRestrictionValue,
    zone: event.zone,
    lat: event.lat, // FORZATO
    lng: event.lng, // FORZATO
    imagePath: event.imagePath,
  );
    _events[index] = updated;
    _saveEvents();
    notifyListeners();
  }

  void requestToJoin(String eventId, String email) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    final event = _events[index];
    if (event.pendingRequests.contains(email)) return;
    if (event.participants.contains(email)) return;

    final updated = event.copyWith(
      pendingRequests: [...event.pendingRequests, email],
    );
    _events[index] = updated;
    _saveEvents();
    notifyListeners();
  }

  void leaveEvent(String eventId, String email) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    final event = _events[index];
    if (!event.participants.contains(email)) return;

    final updated = event.copyWith(
      participants: event.participants.where((p) => p != email).toList(),
    );
    _events[index] = updated;
    _saveEvents();
    notifyListeners();
  }

  void rejectRequest(String eventId, String email) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    final event = _events[index];
    if (!event.pendingRequests.contains(email)) return;

    final updated = event.copyWith(
      pendingRequests: event.pendingRequests.where((p) => p != email).toList(),
    );
    _events[index] = updated;
    _saveEvents();
    notifyListeners();
  }

  void approveRequest(String eventId, String email) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    final event = _events[index];
    if (!event.pendingRequests.contains(email)) return;
    if (event.participants.length >= event.maxParticipants) return;

    final updated = event.copyWith(
      pendingRequests: event.pendingRequests.where((p) => p != email).toList(),
      participants: [...event.participants, email],
    );
    _events[index] = updated;
    _saveEvents();
    notifyListeners();
  }

  // ─────────────────────────────
  // ELIMINAZIONE
  // ─────────────────────────────

  void deleteEvent(String eventId) {
    _events.removeWhere((e) => e.id == eventId);
    _saveEvents();
    notifyListeners();
  }
}