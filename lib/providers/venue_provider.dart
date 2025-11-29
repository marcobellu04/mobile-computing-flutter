import 'package:flutter/material.dart';
import '../models/venue.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VenueProvider extends ChangeNotifier {
  List<Venue> _venues = [];

  List<Venue> get venues => _venues;

  Future<void> loadVenues() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('venues');
    if (data != null) {
      final List list = jsonDecode(data) as List;
      _venues =
          list.map((e) => Venue.fromMap(e as Map<String, dynamic>)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveVenues() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _venues.map((v) => v.toMap()).toList();
    await prefs.setString('venues', jsonEncode(list));
  }

  void addVenue(Venue venue) {
    _venues.add(venue);
    _saveVenues();
    notifyListeners();
  }

  void setVenues(List<Venue> venues) {
    _venues = venues;
    _saveVenues();
    notifyListeners();
  }
}

