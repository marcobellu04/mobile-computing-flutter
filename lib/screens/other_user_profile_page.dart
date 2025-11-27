import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/message_provider.dart';
import 'chat_page.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String userEmail;
  final String userName;
  final String userSurname; // nuovo parametro per cognome

  const OtherUserProfilePage({
    super.key,
    required this.userEmail,
    required this.userName,
    this.userSurname = '',
  });

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  User? _userDetails;

  Future<void> _loadUserDetails() async {
    // In un caso reale potresti caricare dati completi da backend o provider utenti
    setState(() {
      _userDetails = User(
        email: widget.userEmail,
        name: widget.userName,
        surname: widget.userSurname,
        birthDate: DateTime(1990, 6, 15), // valore di default o reale
        gender: 'male', // opzionale
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    if (_userDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profilo utente')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentUserEmail = Provider.of<MessageProvider>(context, listen: false).currentUserEmail;

    return Scaffold(
      appBar: AppBar(title: Text(_userDetails!.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${_userDetails!.name}'),
            const SizedBox(height: 8),
            Text('Cognome: ${_userDetails!.surname}'),
            const SizedBox(height: 8),
            Text('Età: ${_userDetails!.age}'),
            const SizedBox(height: 8),
            Text('Email: ${_userDetails!.email}'),
            const SizedBox(height: 24),
            if (currentUserEmail != null &&
                currentUserEmail != widget.userEmail)
              ElevatedButton.icon(
                icon: const Icon(Icons.message),
                label: const Text('Chatta con questo utente'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        userEmail: currentUserEmail,
                        venueEmail: widget.userEmail,
                        venueName: _userDetails!.name,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
