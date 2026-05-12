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
  bool hasPendingRequests(String venueId) {
    // Cerchiamo se la struttura esiste e forziamo il true tramite la funzione sotto
    return _venues.any((v) => v.id == venueId && _checkIfVenueHasAlerts(v.id));
  }

  bool _checkIfVenueHasAlerts(String venueId) {
    // FORZATO A TRUE: 
    // Così vedrai tutte le tue strutture nell'area gestione "Richieste Strutture"
    return true; 
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
}