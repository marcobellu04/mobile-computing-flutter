import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/message_provider.dart';

class ChatPage extends StatefulWidget {
  final String userEmail;    // Email utente loggato (mittente)
  final String venueEmail;   // Email destinatario chat
  final String venueName;    // Nome destinatario chat

  const ChatPage({
    super.key,
    required this.userEmail,
    required this.venueEmail,
    required this.venueName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = Message(
      senderEmail: widget.userEmail,
      receiverEmail: widget.venueEmail,
      senderName: widget.userEmail.split('@')[0],
      receiverName: widget.venueName,
      text: text,
      timestamp: DateTime.now(),
    );

    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    messageProvider.sendMessage(message);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = Provider.of<MessageProvider>(context);
    final messages = messageProvider.getMessagesBetween(widget.userEmail, widget.venueEmail);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.amber[100],
              radius: 16,
              child: Text(widget.venueName[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.amber)),
            ),
            const SizedBox(width: 10),
            Text(widget.venueName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final msg = messages[messages.length - 1 - index];
                final isMe = msg.senderEmail == widget.userEmail;
                
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 4, top: 4, left: isMe ? 50 : 0, right: isMe ? 0 : 50),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blueAccent : Colors.grey[100],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 5),
                        bottomRight: Radius.circular(isMe ? 5 : 20),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          // Barra di input stile Instagram
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Scrivi un messaggio...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: const Text(
                      "Invia",
                      style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}