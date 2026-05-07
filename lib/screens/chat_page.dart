import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/message_provider.dart';

class ChatPage extends StatefulWidget {
  final String userEmail;    
  final String venueEmail;   
  final String venueName;    
  final String? role;        

  const ChatPage({
    super.key,
    required this.userEmail,
    required this.venueEmail,
    required this.venueName,
    this.role,               
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Segna i messaggi come letti appena si apre la pagina
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MessageProvider>(context, listen: false)
          .markAsRead(widget.userEmail, widget.venueEmail);
    });
  }

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

    // Se arrivano nuovi messaggi mentre la chat è aperta, segnali come letti
    if (messageProvider.getUnreadCount(widget.userEmail, widget.venueEmail) > 0) {
      Future.microtask(() => messageProvider.markAsRead(widget.userEmail, widget.venueEmail));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.amber[100],
              radius: 18,
              child: Text(
                widget.venueName.isNotEmpty ? widget.venueName[0].toUpperCase() : "?", 
                style: const TextStyle(fontSize: 14, color: Colors.amber, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.venueName, 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
                if (widget.role != null)
                  Text(
                    widget.role!,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
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