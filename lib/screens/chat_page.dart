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

    // Controllo per evitare messaggi a se stessi
    if (widget.userEmail == widget.venueEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Non puoi inviare messaggi a te stesso")),
      );
      return;
    }

    final message = Message(
      senderEmail: widget.userEmail,
      receiverEmail: widget.venueEmail,
      senderName: widget.userEmail.split('@')[0],    // O da profilo
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
      appBar: AppBar(title: Text('Chat con ${widget.venueName}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final msg = messages[messages.length - 1 - index];
                final isMe = msg.senderEmail == widget.userEmail;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.deepPurple[300] : Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Scrivi un messaggio...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: (widget.userEmail == widget.venueEmail) ? null : _sendMessage,
                  color: (widget.userEmail == widget.venueEmail) ? Colors.grey : Colors.deepPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
