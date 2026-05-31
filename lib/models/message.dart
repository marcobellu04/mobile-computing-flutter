import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderEmail;
  final String receiverEmail;
  final String text;
  final DateTime timestamp;
  final String? senderName;
  final String? receiverName;
  bool isRead;

  Message({
    required this.id,
    required this.senderEmail,
    required this.receiverEmail,
    required this.text,
    required this.timestamp,
    this.senderName,
    this.receiverName,
    this.isRead = false,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    DateTime parsedTimestamp;

    if (map['timestamp'] is Timestamp) {
      parsedTimestamp = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      parsedTimestamp = DateTime.parse(map['timestamp']);
    } else {
      parsedTimestamp = DateTime.now();
    }

    return Message(
      id: map['id'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      receiverEmail: map['receiverEmail'] ?? '',
      text: map['text'] ?? '',
      timestamp: parsedTimestamp,
      senderName: map['senderName'],
      receiverName: map['receiverName'],
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'senderName': senderName,
      'receiverName': receiverName,
      'isRead': isRead,
    };
  }
}