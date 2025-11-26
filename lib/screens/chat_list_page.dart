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
      appBar: AppBar(title: const Text('Le tue chat')),
      body: ListView.separated(
        itemCount: chats.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: const Icon(Icons.chat_bubble),
            title: Text(chat.userName),
            subtitle: Text(chat.lastMessage),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ChatPage(
                  userEmail: currentUserEmail,
                  venueEmail: chat.userEmail,
                  venueName: chat.userName,
                ),
              ));
            },
          );
        },
      ),
    );
  }
}
