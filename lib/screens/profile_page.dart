import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_app/screens/user_profile_page.dart';
import 'chat_page.dart';

class ProfilePage extends StatelessWidget {
  final String currentUserEmail;
  final String profileUserEmail;
  final String profileUserName;

  const ProfilePage({
    super.key,
    required this.currentUserEmail,
    required this.profileUserEmail,
    required this.profileUserName,
  });

  Future<bool> _showLogoutConfirmation(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confermi di voler uscire?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profilo di $profileUserName')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Dati personali'),
              subtitle: const Text('Nome, Email, ...'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserProfilePage()),
                );
              },
            ),
            const Divider(),
            if (currentUserEmail != profileUserEmail)
              ElevatedButton.icon(
                icon: const Icon(Icons.message),
                label: const Text('Chatta con questo utente'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        userEmail: currentUserEmail,
                        venueEmail: profileUserEmail,
                        venueName: profileUserName,
                      ),
                    ),
                  );
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Privacy'),
              onTap: () {
                // Gestisci impostazioni privacy
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifiche'),
              onTap: () {
                // Gestisci impostazioni notifiche
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Esci'),
              onTap: () async {
                final confirmed = await _showLogoutConfirmation(context);
                if (confirmed) {
                  await _logout(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
