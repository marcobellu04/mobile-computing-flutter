import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/message_provider.dart';
import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  final String currentUserEmail;
  const ChatListPage({super.key, required this.currentUserEmail});

  @override
  Widget build(BuildContext context) {
    final messageProvider = Provider.of<MessageProvider>(context);
    final chats = messageProvider.getChatSummariesForUser(currentUserEmail);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Messaggi', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: chats.isEmpty 
        ? const Center(child: Text("Nessuna conversazione attiva"))
        : ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 5),
            itemBuilder: (context, index) {
              final chat = chats[index];
              // SIMULAZIONE NOTIFICA: 
              // Qui potresti avere una logica nel provider tipo chat.hasUnread
              bool hasUnread = index == 0; // Solo come esempio visivo per il primo elemento

              return ListTile(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatPage(
                      userEmail: currentUserEmail,
                      venueEmail: chat.userEmail,
                      venueName: chat.userName,
                    ),
                  ));
                },
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  child: Text(chat.userName[0].toUpperCase()),
                ),
                title: Text(chat.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: hasUnread ? Colors.black : Colors.grey, fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasUnread)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                      ),
                    const SizedBox(height: 5),
                    const Text("Adesso", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
    );
  }
}