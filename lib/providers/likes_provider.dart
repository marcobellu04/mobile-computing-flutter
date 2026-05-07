import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LikesProvider extends ChangeNotifier {
  final Map<String, Set<String>> _likesByUser = {};
  final Map<String, Set<String>> _venueLikesByUser = {}; // Nuova mappa per strutture
  
  String? _currentUserEmail;

  Set<String> likesFor(String userEmail) => _likesByUser[userEmail] ?? <String>{};
  Set<String> venueLikesFor(String userEmail) => _venueLikesByUser[userEmail] ?? <String>{};

  bool isLiked(String eventId) {
    if (_currentUserEmail == null) return false;
    return likesFor(_currentUserEmail!).contains(eventId);
  }

  bool isVenueLiked(String venueId) { // Nuovo check per strutture
    if (_currentUserEmail == null) return false;
    return venueLikesFor(_currentUserEmail!).contains(venueId);
  }

  Future<void> toggleLike(String userEmail, String eventId, {String? ownerEmail}) async {
    if (ownerEmail != null && userEmail.trim().toLowerCase() == ownerEmail.trim().toLowerCase()) return; 

    final set = _likesByUser.putIfAbsent(userEmail, () => <String>{});
    if (set.contains(eventId)) { set.remove(eventId); } else { set.add(eventId); }
    await _saveForUser(userEmail, isVenue: false);
    notifyListeners();
  }

  Future<void> toggleVenueLike(String userEmail, String venueId, {String? ownerEmail}) async {
    if (ownerEmail != null && userEmail.trim().toLowerCase() == ownerEmail.trim().toLowerCase()) return;

    final set = _venueLikesByUser.putIfAbsent(userEmail, () => <String>{});
    if (set.contains(venueId)) { set.remove(venueId); } else { set.add(venueId); }
    await _saveForUser(userEmail, isVenue: true);
    notifyListeners();
  }

  Future<void> loadForUser(String userEmail) async {
    _currentUserEmail = userEmail;
    final prefs = await SharedPreferences.getInstance();
    
    // Carica Eventi
    final eventData = prefs.getString('likes_$userEmail');
    if (eventData != null) {
      _likesByUser[userEmail] = (jsonDecode(eventData) as List).map((e) => e as String).toSet();
    }
    
    // Carica Strutture
    final venueData = prefs.getString('venue_likes_$userEmail');
    if (venueData != null) {
      _venueLikesByUser[userEmail] = (jsonDecode(venueData) as List).map((e) => e as String).toSet();
    }
    notifyListeners();
  }

  Future<void> _saveForUser(String userEmail, {required bool isVenue}) async {
    final prefs = await SharedPreferences.getInstance();
    if (isVenue) {
      final list = venueLikesFor(userEmail).toList();
      await prefs.setString('venue_likes_$userEmail', jsonEncode(list));
    } else {
      final list = likesFor(userEmail).toList();
      await prefs.setString('likes_$userEmail', jsonEncode(list));
    }
  }
}