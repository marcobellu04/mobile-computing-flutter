import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LikesProvider extends ChangeNotifier {
  final Map<String, Set<String>> _likesByUser = {};
  final Map<String, Set<String>> _venueLikesByUser = {};

  String? _currentUserEmail;

  Set<String> likesFor(String userEmail) => _likesByUser[userEmail] ?? <String>{};

  Set<String> venueLikesFor(String userEmail) =>
      _venueLikesByUser[userEmail] ?? <String>{};

  bool isLiked(String eventId) {
    if (_currentUserEmail == null) return false;
    return likesFor(_currentUserEmail!).contains(eventId);
  }

  bool isVenueLiked(String venueId) {
    if (_currentUserEmail == null) return false;
    return venueLikesFor(_currentUserEmail!).contains(venueId);
  }

  Future<void> toggleLike(
    String userEmail,
    String eventId, {
    String? ownerEmail,
  }) async {
    if (ownerEmail != null &&
        userEmail.trim().toLowerCase() == ownerEmail.trim().toLowerCase()) {
      return;
    }

    final set = _likesByUser.putIfAbsent(userEmail, () => <String>{});

    if (set.contains(eventId)) {
      set.remove(eventId);
    } else {
      set.add(eventId);
    }

    await _saveForUser(userEmail);
    notifyListeners();
  }

  Future<void> toggleVenueLike(
    String userEmail,
    String venueId, {
    String? ownerEmail,
  }) async {
    if (ownerEmail != null &&
        userEmail.trim().toLowerCase() == ownerEmail.trim().toLowerCase()) {
      return;
    }

    final set = _venueLikesByUser.putIfAbsent(userEmail, () => <String>{});

    if (set.contains(venueId)) {
      set.remove(venueId);
    } else {
      set.add(venueId);
    }

    await _saveForUser(userEmail);
    notifyListeners();
  }

  Future<void> loadForUser(String userEmail) async {
    _currentUserEmail = userEmail;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_likes')
          .doc(userEmail)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        _likesByUser[userEmail] =
            List<String>.from(data['eventLikes'] ?? []).toSet();

        _venueLikesByUser[userEmail] =
            List<String>.from(data['venueLikes'] ?? []).toSet();
      } else {
        _likesByUser[userEmail] = <String>{};
        _venueLikesByUser[userEmail] = <String>{};
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Errore caricamento like da Firestore: $e");
    }
  }

  Future<void> _saveForUser(String userEmail) async {
    try {
      await FirebaseFirestore.instance
          .collection('user_likes')
          .doc(userEmail)
          .set({
        'email': userEmail,
        'eventLikes': likesFor(userEmail).toList(),
        'venueLikes': venueLikesFor(userEmail).toList(),
      });

    } catch (e) {
      debugPrint("Errore salvataggio like su Firestore: $e");
    }
  }
}