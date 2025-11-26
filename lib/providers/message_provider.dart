import 'package:flutter/material.dart';
import '../models/message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MessageProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  String? _currentUserEmail;

  String? get currentUserEmail => _currentUserEmail;

  void setCurrentUserEmail(String email) {
    _currentUserEmail = email;
    notifyListeners();
  }

  List<Message> getMessagesBetween(String userEmail, String otherEmail) {
    return _messages.where((m) =>
      (m.senderEmail == userEmail && m.receiverEmail == otherEmail) ||
      (m.senderEmail == otherEmail && m.receiverEmail == userEmail)
    ).toList();
  }

  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('messages');
    if (data != null) {
      final List list = jsonDecode(data);
      _messages.clear();
      _messages.addAll(list.map((e) => Message.fromMap(e)));
      notifyListeners();
    }
  }

  Future<void> saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('messages', jsonEncode(_messages.map((m) => m.toMap()).toList()));
  }

  void sendMessage(Message message) {
    _messages.add(message);
    saveMessages();
    notifyListeners();
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
      if (existing == null || msg.timestamp.isAfter(existing.lastMessageTimestamp)) {
        summaries[chatUserEmail] = ChatSummary(
          userEmail: chatUserEmail,
          userName: chatUserName,
          lastMessage: msg.text,
          lastMessageTimestamp: msg.timestamp,
        );
      }
    }
    final list = summaries.values.toList();
    list.sort((a,b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));
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
