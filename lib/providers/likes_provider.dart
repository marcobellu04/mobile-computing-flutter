import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LikesProvider extends ChangeNotifier {
  final Map<String, Set<String>> _likesByUser = {};

  Set<String> likesFor(String userEmail) {
    return _likesByUser[userEmail] ?? <String>{};
  }

  bool isLiked(String userEmail, String eventId) {
    return likesFor(userEmail).contains(eventId);
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
    final prefs = await SharedPreferences.getInstance();
    final key = 'likes_$userEmail';
    final data = prefs.getString(key);
    if (data != null) {
      final List list = jsonDecode(data) as List;
      _likesByUser[userEmail] = list.map((e) => e as String).toSet();
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
