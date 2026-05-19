import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/venue.dart';

class VenueProvider extends ChangeNotifier {
  List<Venue> _venues = [];

  List<Venue> get venues => _venues;

  VenueProvider() {
    loadVenues();
  }

  // ─────────────────────────────
  // GESTIONE RICHIESTE (SBLOCCATA PER TEST)
  // ─────────────────────────────

  /// Verifica se una specifica struttura ha richieste pendenti.
 bool hasPendingRequests(String venueId, List<dynamic> allRequests) {
    // Cerchiamo se tra tutte le prenotazioni ce n'è una per questa struttura con stato 'pending'
    return allRequests.any((r) => r.venueId == venueId && r.status == 'pending');
  }

  // ─────────────────────────────
  // CARICAMENTO E SALVATAGGIO
  // ─────────────────────────────

  Future<void> loadVenues() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('venues');
    if (data != null) {
      try {
        final List list = jsonDecode(data) as List;
        _venues = list.map((e) => Venue.fromMap(e as Map<String, dynamic>)).toList();
        notifyListeners();
      } catch (e) {
        print("Errore nel caricamento delle strutture: $e");
      }
    }
  }

  Future<void> _saveVenues() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _venues.map((v) => v.toMap()).toList();
    await prefs.setString('venues', jsonEncode(list));
  }

  // ─────────────────────────────
  // OPERAZIONI CRUD
  // ─────────────────────────────

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

  void updateVenue(Venue updatedVenue) {
    final index = _venues.indexWhere((v) => v.id == updatedVenue.id);
    if (index != -1) {
      _venues[index] = updatedVenue;
      _saveVenues();
      notifyListeners();
    }
  }

  void updateVenueImage(String venueId, String newPath) {
    final index = _venues.indexWhere((v) => v.id == venueId);
    if (index != -1) {
      _venues[index] = _venues[index].copyWith(imagePath: newPath);
      _saveVenues();
      notifyListeners();
    }
  }

  void deleteVenue(String venueId) {
    _venues.removeWhere((v) => v.id == venueId);
    _saveVenues();
    notifyListeners();
  }

  void deleteVenuesByOwner(String ownerEmail) {
    _venues.removeWhere((v) => v.ownerEmail.trim().toLowerCase() == ownerEmail.trim().toLowerCase());
    _saveVenues();
    notifyListeners();
  }
}
