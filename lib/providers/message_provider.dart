import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class MessageProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  String? _currentUserEmail;

  String? get currentUserEmail => _currentUserEmail;

  void setCurrentUserEmail(String email) {
    _currentUserEmail = email;
    notifyListeners();
  }

  int getUnreadCount(String myEmail, String otherEmail) {
    return _messages
        .where(
          (m) =>
              m.senderEmail == otherEmail &&
              m.receiverEmail == myEmail &&
              m.isRead == false,
        )
        .length;
  }

  Future<void> markAsRead(String myEmail, String otherEmail) async {
    bool changed = false;

    for (var m in _messages) {
      if (m.senderEmail == otherEmail &&
          m.receiverEmail == myEmail &&
          !m.isRead) {
        m.isRead = true;
        changed = true;

        await FirebaseFirestore.instance
            .collection('messages')
            .doc(m.id)
            .update({'isRead': true});
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  List<Message> getMessagesBetween(String userEmail, String otherEmail) {
    final list = _messages
        .where(
          (m) =>
              (m.senderEmail == userEmail && m.receiverEmail == otherEmail) ||
              (m.senderEmail == otherEmail && m.receiverEmail == userEmail),
        )
        .toList();

    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  void loadMessages() {
  FirebaseFirestore.instance
      .collection('messages')
      .orderBy('timestamp')
      .snapshots()
      .listen((snapshot) {
    _messages.clear();

    _messages.addAll(
      snapshot.docs.map((doc) {
        final data = doc.data();

        if ((data['id'] ?? '').toString().isEmpty) {
          data['id'] = doc.id;
        }

        return Message.fromMap(data);
      }),
    );

    notifyListeners();
  });
}

  Future<void> sendMessage(Message message) async {
  try {
    final data = message.toMap();
    data['timestamp'] = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(message.id)
        .set(data);
  } catch (e) {
    debugPrint("Errore invio messaggio su Firestore: $e");
  }
}

  List<ChatSummary> getChatSummariesForUser(String userEmail) {
    final Map<String, ChatSummary> summaries = {};

    for (final msg in _messages) {
      if (msg.senderEmail != userEmail && msg.receiverEmail != userEmail) {
        continue;
      }

      String chatUserEmail;
      String chatUserName;

      if (msg.senderEmail == userEmail) {
        chatUserEmail = msg.receiverEmail;
        chatUserName = msg.receiverName ?? msg.receiverEmail;
      } else {
        chatUserEmail = msg.senderEmail;
        chatUserName = msg.senderName ?? msg.senderEmail;
      }

      final existing = summaries[chatUserEmail];

      if (existing == null ||
          msg.timestamp.isAfter(existing.lastMessageTimestamp)) {
        summaries[chatUserEmail] = ChatSummary(
          userEmail: chatUserEmail,
          userName: chatUserName,
          lastMessage: msg.text,
          lastMessageTimestamp: msg.timestamp,
        );
      }
    }

    final list = summaries.values.toList();
    list.sort((a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));

    return list;
  }
}

class ChatSummary {
  final String userEmail;
  final String userName;
  final String lastMessage;
  final DateTime lastMessageTimestamp;

  ChatSummary({
    required this.userEmail,
    required this.userName,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });
}