import 'package:flutter/material.dart';

import '../models/event.dart';

class EventProvider extends ChangeNotifier {
  List<Event> _events = [];

  List<Event> get events => _events;

  // Caricamento iniziale o impostazione eventi
  void setEvents(List<Event> events) {
    _events = events;
    notifyListeners();
  }

  // Aggiungi un nuovo evento
  void addEvent(Event event) {
    _events.add(event);
    notifyListeners();
  }

  // Aggiorna un evento esistente basandosi su id univoco (assumendo che Event abbia id)
  void updateEvent(Event updatedEvent) {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      notifyListeners();
    }
  }

  // Altri metodi (rimuovi, filtra ecc.) se presenti
}
