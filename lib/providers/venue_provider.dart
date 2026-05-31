import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/venue.dart';

class VenueProvider extends ChangeNotifier {
  List<Venue> _venues = [];

  List<Venue> get venues => _venues;

  VenueProvider() {
    loadVenues();
  }

  bool hasPendingRequests(String venueId, List<dynamic> allRequests) {
    return allRequests.any(
      (r) => r.venueId == venueId && r.status == 'pending',
    );
  }

  Future<void> loadVenues() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('venues').get();

      _venues = snapshot.docs
          .map((doc) => Venue.fromMap(doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint("Errore caricamento strutture da Firestore: $e");
    }
  }

  Future<void> addVenue(Venue venue) async {
    try {
      await FirebaseFirestore.instance
          .collection('venues')
          .doc(venue.id)
          .set(venue.toMap());

      _venues.add(venue);
      notifyListeners();
    } catch (e) {
      debugPrint("Errore salvataggio struttura su Firestore: $e");
    }
  }

  Future<void> setVenues(List<Venue> venues) async {
    _venues = venues;

    for (final venue in venues) {
      await FirebaseFirestore.instance
          .collection('venues')
          .doc(venue.id)
          .set(venue.toMap());
    }

    notifyListeners();
  }

  Future<void> updateVenue(Venue updatedVenue) async {
    final index = _venues.indexWhere((v) => v.id == updatedVenue.id);

    if (index != -1) {
      _venues[index] = updatedVenue;

      await FirebaseFirestore.instance
          .collection('venues')
          .doc(updatedVenue.id)
          .set(updatedVenue.toMap());

      notifyListeners();
    }
  }

  Future<void> updateVenueImage(String venueId, String newPath) async {
    final index = _venues.indexWhere((v) => v.id == venueId);

    if (index != -1) {
      final updatedVenue = _venues[index].copyWith(imagePath: newPath);
      _venues[index] = updatedVenue;

      await FirebaseFirestore.instance
          .collection('venues')
          .doc(venueId)
          .set(updatedVenue.toMap());

      notifyListeners();
    }
  }

  Future<void> deleteVenue(String venueId) async {
    _venues.removeWhere((v) => v.id == venueId);

    await FirebaseFirestore.instance
        .collection('venues')
        .doc(venueId)
        .delete();

    notifyListeners();
  }

  Future<void> deleteVenuesByOwner(String ownerEmail) async {
    final toDelete = _venues
        .where((v) =>
            v.ownerEmail.trim().toLowerCase() ==
            ownerEmail.trim().toLowerCase())
        .toList();

    for (final venue in toDelete) {
      await FirebaseFirestore.instance
          .collection('venues')
          .doc(venue.id)
          .delete();
    }

    _venues.removeWhere((v) =>
        v.ownerEmail.trim().toLowerCase() ==
        ownerEmail.trim().toLowerCase());

    notifyListeners();
  }
}