import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/venue.dart';

class VenueProvider extends ChangeNotifier {
  List<Venue> _venues = [];

  List<Venue> get venues => _venues;

  // Costruttore: carica le strutture salvate non appena il provider viene creato
  VenueProvider() {
    loadVenues();
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
        // Venue.fromMap ora gestisce automaticamente imagePath, lat e lng
        _venues = list.map((e) => Venue.fromMap(e as Map<String, dynamic>)).toList();
        notifyListeners();
      } catch (e) {
        print("Errore nel caricamento delle strutture: $e");
      }
    }
  }

  Future<void> _saveVenues() async {
    final prefs = await SharedPreferences.getInstance();
    // Il toMap() include ora tutti i nuovi campi, garantendo la persistenza
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

  /// Aggiorna una struttura esistente (utile per cambiare immagine o info)
  void updateVenue(Venue updatedVenue) {
    final index = _venues.indexWhere((v) => v.id == updatedVenue.id);
    if (index != -1) {
      _venues[index] = updatedVenue;
      _saveVenues();
      notifyListeners();
    }
  }

  /// Metodo rapido per aggiornare solo l'immagine di una struttura
  void updateVenueImage(String venueId, String newPath) {
    final index = _venues.indexWhere((v) => v.id == venueId);
    if (index != -1) {
      _venues[index] = _venues[index].copyWith(imagePath: newPath);
      _saveVenues();
      notifyListeners();
    }
  }

  /// Elimina una struttura dalla lista e aggiorna il database locale
  void deleteVenue(String venueId) {
    _venues.removeWhere((v) => v.id == venueId);
    _saveVenues();
    notifyListeners();
  }
}