import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';

class EventProvider extends ChangeNotifier {
  List<Event> _events = [];

  List<Event> get events => _events;

  Future<void> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('events');
    if (data != null) {
      final List list = jsonDecode(data) as List;
      _events = list.map((e) => Event.fromMap(e as Map<String, dynamic>)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _events.map((e) => e.toMap()).toList();
    await prefs.setString('events', jsonEncode(list));
  }

  void setEvents(List<Event> events) {
    _events = events;
    _saveEvents();
    notifyListeners();
  }

  void addEvent(Event event) {
    _events.add(event);
    _saveEvents();
    notifyListeners();
  }

  void updateEvent(Event updatedEvent) {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      _saveEvents();
      notifyListeners();
    }
  }
}
