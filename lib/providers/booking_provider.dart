import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VenueBookingRequest {
  final String id;
  final String senderEmail;
  final String venueEmail;
  final String venueName;
  final String venueAddress;
  final String date;
  final String timeRange;
  final int peopleCount;
  final String message;
  String status;

  VenueBookingRequest({
    required this.id,
    required this.senderEmail,
    required this.venueEmail,
    required this.venueName,
    required this.venueAddress,
    required this.date,
    required this.timeRange,
    required this.peopleCount,
    required this.message,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderEmail': senderEmail,
        'venueEmail': venueEmail,
        'venueName': venueName,
        'venueAddress': venueAddress,
        'date': date,
        'timeRange': timeRange,
        'peopleCount': peopleCount,
        'message': message,
        'status': status,
      };

  factory VenueBookingRequest.fromMap(Map<String, dynamic> map) {
    return VenueBookingRequest(
      id: map['id'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      venueEmail: map['venueEmail'] ?? '',
      venueName: map['venueName'] ?? '',
      venueAddress: map['venueAddress'] ?? '',
      date: map['date'] ?? '',
      timeRange: map['timeRange'] ?? '',
      peopleCount: map['peopleCount'] ?? 0,
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }
}

class BookingProvider with ChangeNotifier {
  List<VenueBookingRequest> _requests = [];

  List<VenueBookingRequest> get requests => _requests;

  BookingProvider() {
    loadRequests();
  }

  List<VenueBookingRequest> getPendingRequestsForOwner(String ownerEmail) {
    return _requests
        .where(
          (r) =>
              r.venueEmail.trim().toLowerCase() ==
                  ownerEmail.trim().toLowerCase() &&
              r.status == 'pending',
        )
        .toList();
  }

  Future<void> loadRequests() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('booking_requests')
          .get();

      _requests = snapshot.docs
          .map((doc) => VenueBookingRequest.fromMap(doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint("Errore caricamento richieste da Firestore: $e");
    }
  }

  Future<void> sendRequest(VenueBookingRequest request) async {
    try {
      await FirebaseFirestore.instance
          .collection('booking_requests')
          .doc(request.id)
          .set(request.toMap());

      _requests.add(request);
      notifyListeners();
    } catch (e) {
      debugPrint("Errore invio richiesta su Firestore: $e");
    }
  }

  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    final index = _requests.indexWhere((r) => r.id == requestId);

    if (index != -1) {
      try {
        _requests[index].status = newStatus;

        await FirebaseFirestore.instance
            .collection('booking_requests')
            .doc(requestId)
            .update({
          'status': newStatus,
        });

        notifyListeners();
      } catch (e) {
        debugPrint("Errore aggiornamento richiesta su Firestore: $e");
      }
    }
  }
}