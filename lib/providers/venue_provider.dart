import 'package:flutter/material.dart';
import '../models/venue.dart';

class VenueProvider with ChangeNotifier {
  final List<Venue> _venues = []; // Parte vuota

  List<Venue> get venues => [..._venues];

  void addVenue(Venue venue) {
    _venues.add(venue);
    notifyListeners();
  }
}

