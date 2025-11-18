import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageProvider extends ChangeNotifier {
  final List<Message> _messages = [];

  List<Message> get allMessages => _messages;

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
}
