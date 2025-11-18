import 'package:flutter/material.dart';
import '../models/event.dart';

class EventProvider extends ChangeNotifier {
  final List<Event> _events = [];

  List<Event> get events => _events;

  void addEvent(Event event) {
    _events.add(event);
    notifyListeners();
  }

  void updateEvent(Event updatedEvent) {
    final index = _events.indexWhere((e) => e.name == updatedEvent.name && e.date == updatedEvent.date);
    if (index != -1) {
      _events[index] = updatedEvent;
      notifyListeners();
    }
  }
}
