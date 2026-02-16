import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LikesProvider extends ChangeNotifier {
  // Mappa che associa l'email dell'utente al set dei suoi ID evento preferiti
  final Map<String, Set<String>> _likesByUser = {};
  
  // Teniamo traccia dell'utente corrente per semplificare le chiamate dalla UI
  String? _currentUserEmail;

  Set<String> likesFor(String userEmail) {
    return _likesByUser[userEmail] ?? <String>{};
  }

  // MODIFICATO: Accetta l'ID evento e usa l'utente corrente internamente
  bool isLiked(String eventId) {
    if (_currentUserEmail == null) return false;
    return likesFor(_currentUserEmail!).contains(eventId);
  }

  Future<void> toggleLike(String userEmail, String eventId) async {
    final set = _likesByUser.putIfAbsent(userEmail, () => <String>{});
    if (set.contains(eventId)) {
      set.remove(eventId);
    } else {
      set.add(eventId);
    }
    await _saveForUser(userEmail);
    notifyListeners();
  }

  Future<void> loadForUser(String userEmail) async {
    _currentUserEmail = userEmail; // Memorizziamo l'utente attivo
    final prefs = await SharedPreferences.getInstance();
    final key = 'likes_$userEmail';
    final data = prefs.getString(key);
    if (data != null) {
      try {
        final List list = jsonDecode(data) as List;
        _likesByUser[userEmail] = list.map((e) => e as String).toSet();
      } catch (e) {
        _likesByUser[userEmail] = <String>{};
      }
    }
    notifyListeners();
  }

  Future<void> _saveForUser(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'likes_$userEmail';
    final list = likesFor(userEmail).toList();
    await prefs.setString(key, jsonEncode(list));
  }
}