import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'user_profile_page.dart';
import 'chat_page.dart';
import '../models/user.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  final String currentUserEmail;
  final String profileUserEmail;
  final String profileUserName;

  const ProfilePage({
    super.key,
    required this.currentUserEmail,
    required this.profileUserEmail,
    required this.profileUserName,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _notificationsEnabled = true;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadPrefs();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = widget.profileUserEmail;
    final savedPath = prefs.getString('user_image_$email');
  if (savedPath != null) {
    setState(() { _profileImage = File(savedPath); });
  }
    final jsonString = prefs.getString('user_data_$email');
    if (jsonString == null) return;
    final Map<String, dynamic> map = jsonDecode(jsonString);
    setState(() {
      _user = User.fromMap(map);
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
  }

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
            child: const Text('Esci', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildHeader() {
  final String name = _user != null ? '${_user!.name} ${_user!.surname}' : widget.profileUserName;
  final String email = _user != null ? _user!.email : widget.profileUserEmail;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F3F3),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[400],
          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
          child: _profileImage == null 
              ? const Icon(Icons.person, color: Colors.black) 
              : null,
        ),
        const SizedBox(width: 16),
        // ... resto della Row uguale ...
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(email, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.black45),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final bool isOwnProfile = widget.currentUserEmail == widget.profileUserEmail;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            const Text(
              'Other settings',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Card impostazioni principali
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: Colors.black54),
                    title: const Text('Profile details', style: TextStyle(color: Colors.black)),
                    subtitle: _user == null
                        ? null
                        : Text('${_user!.name} ${_user!.surname}',
                            style: const TextStyle(color: Colors.black54)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserProfilePage()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Colors.black12),
                  SwitchListTile(
                    activeColor: Colors.amber,
                    value: _notificationsEnabled,
                    onChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                      _savePrefs();
                    },
                    secondary: const Icon(Icons.notifications_none, color: Colors.black54),
                    title: const Text('Notifications', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Card chat + logout
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (!isOwnProfile) ...[
                    ListTile(
                      leading: const Icon(Icons.message, color: Colors.black54),
                      title: const Text('Chatta con questo utente', style: TextStyle(color: Colors.black)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              userEmail: widget.currentUserEmail,
                              venueEmail: widget.profileUserEmail,
                              venueName: widget.profileUserName,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Colors.black12),
                  ],
                  ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFFF4A4A)),
                    title: const Text('Log out', style: TextStyle(color: Color(0xFFFF4A4A))),
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
          ],
        ),
      ),
    );
  }
}