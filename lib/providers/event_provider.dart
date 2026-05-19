import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';

class EventProvider extends ChangeNotifier {
  List<Event> _events = [];

  // MODIFICA: Restituisce solo eventi la cui data è oggi o nel futuro
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

  // --- CARICAMENTO E SALVATAGGIO ---

  Future<void> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('events');
    if (data != null) {
      try {
        final List list = jsonDecode(data);
        _events = list.map((e) => Event.fromMap(e as Map<String, dynamic>)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint("Errore caricamento eventi: $e");
      }
    }
  }

  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _events.map((e) => e.toMap()).toList();
      await prefs.setString('events', jsonEncode(list));
    } catch (e) {
      debugPrint("Errore salvataggio eventi: $e");
    }
  }

  // --- AGGIUNTA NUOVO EVENTO ---

  void addEvent(Event event) {
    _events.add(event);
    _saveEvents(); 
    notifyListeners(); 
  }

  // --- LOGICA PARTECIPAZIONE ---

  void joinEvent(String eventId, String email) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    final event = _events[index];
    if (event.participants.contains(email)) return;

    _events[index] = event.copyWith(
      participants: [...event.participants, email],
    );
    _saveEvents();
    notifyListeners();
  }

  void requestToJoin(String eventId, String email) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    final event = _events[index];
    if (event.pendingRequests.contains(email) || event.participants.contains(email)) return;

    _events[index] = event.copyWith(
      pendingRequests: [...event.pendingRequests, email],
    );
    _saveEvents();
    notifyListeners();
  }

  void approveRequest(String eventId, String userEmail) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    final event = _events[index];

    _events[index] = event.copyWith(
      pendingRequests: event.pendingRequests.where((e) => e != userEmail).toList(),
      participants: [...event.participants, userEmail],
    );
    _saveEvents();
    notifyListeners();
  }

  void rejectRequest(String eventId, String userEmail) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    final event = _events[index];

    _events[index] = event.copyWith(
      pendingRequests: event.pendingRequests.where((e) => e != userEmail).toList(),
    );
    _saveEvents();
    notifyListeners();
  }

  // --- CANCELLAZIONE ---

  void deleteEvent(String eventId) {
    _events.removeWhere((e) => e.id == eventId);
    _saveEvents();
    notifyListeners();
  }

  void deleteEventsByOwner(String ownerEmail) {
    _events.removeWhere((e) => e.ownerEmail.trim().toLowerCase() == ownerEmail.trim().toLowerCase());
    _saveEvents();
    notifyListeners();
  }

  // --- GETTERS PER FILTRI ---
  
  List<Event> getUpcomingParticipations(String email) {
    if (email.isEmpty) return [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _events.where((e) => 
      e.participants.contains(email) && 
      (e.date.isAfter(today) || e.date.isAtSameMomentAs(today))
    ).toList();
  }

  // --- AGGIORNAMENTO EVENTO ESISTENTE ---
  void updateEvent(Event updatedEvent) {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      _saveEvents(); 
      notifyListeners(); 
    }
  }

  // --- LOGICA NOTIFICHE ---

  /// Restituisce il numero totale di richieste pendenti per tutti gli eventi di un utente
  int getTotalPendingRequestsForOwner(String ownerEmail) {
    return _events
        .where((e) => e.ownerEmail.trim().toLowerCase() == ownerEmail.trim().toLowerCase())
        .fold(0, (sum, event) => sum + event.pendingRequests.length);
  }

  /// Restituisce true se c'è almeno una richiesta pendente per quell'organizzatore
  bool hasNotifications(String ownerEmail) {
    return getTotalPendingRequestsForOwner(ownerEmail) > 0;
  }

  int countPendingRequestsForOwner(String ownerEmail) {
  return _events
      .where((e) => e.ownerEmail.trim().toLowerCase() == ownerEmail.trim().toLowerCase())
      .fold(0, (sum, event) => sum + event.pendingRequests.length);
}
}