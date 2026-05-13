import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  factory VenueBookingRequest.fromMap(Map<String, dynamic> map) => VenueBookingRequest(
    id: map['id'],
    senderEmail: map['senderEmail'],
    venueEmail: map['venueEmail'],
    venueName: map['venueName'],
    venueAddress: map['venueAddress'] ?? "",
    date: map['date'],
    timeRange: map['timeRange'],
    peopleCount: map['peopleCount'],
    message: map['message'],
    status: map['status'] ?? 'pending',
  );
}

class BookingProvider with ChangeNotifier {
  List<VenueBookingRequest> _requests = [];
  List<VenueBookingRequest> get requests => _requests;

  BookingProvider() { loadRequests(); }

  // Restituisce le richieste pendenti per una specifica email proprietario
  List<VenueBookingRequest> getPendingRequestsForOwner(String ownerEmail) {
    return _requests.where((r) => r.venueEmail == ownerEmail && r.status == 'pending').toList();
  }

  Future<void> sendRequest(VenueBookingRequest request) async {
    _requests.add(request);
    await saveRequests();
    notifyListeners();
  }

  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index].status = newStatus;
      await saveRequests();
      notifyListeners();
    }
  }

  Future<void> saveRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _requests.map((r) => r.toMap()).toList();
    await prefs.setString('booking_requests', jsonEncode(data));
  }

  Future<void> loadRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('booking_requests');
    if (dataString != null) {
      final List<dynamic> decoded = jsonDecode(dataString);
      _requests = decoded.map((item) => VenueBookingRequest.fromMap(item)).toList();
      notifyListeners();
    }
  }
}