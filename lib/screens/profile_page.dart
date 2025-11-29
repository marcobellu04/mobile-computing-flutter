import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'user_profile_page.dart';
import 'chat_page.dart';
import '../models/user.dart';
import '../providers/theme_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadPrefs();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = widget.profileUserEmail;
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
      _notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;
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
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildHeader(bool isDark) {
    // Usa SEMPRE _user se presente
    final String name;
    final String email;
    if (_user != null) {
      name = '${_user!.name} ${_user!.surname}';
      email = _user!.email;
    } else {
      name = widget.profileUserName;
      email = widget.profileUserEmail;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isDark ? Colors.grey[700] : Colors.grey[400],
            child: Icon(Icons.person,
                color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: isDark ? Colors.white70 : Colors.black45),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isOwnProfile =
        widget.currentUserEmail == widget.profileUserEmail;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101010) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF101010) : Colors.white,
        elevation: 0,
        iconTheme:
            IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
          'Settings',
          style:
              TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 24),
            Text(
              'Other settings',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),

            // Card impostazioni principali
            Container(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.person_outline,
                        color: isDark ? Colors.white70 : Colors.black54),
                    title: Text('Profile details',
                        style: TextStyle(
                            color:
                                isDark ? Colors.white : Colors.black)),
                    subtitle: _user == null
                        ? null
                        : Text(
                            '${_user!.name} ${_user!.surname}',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black54),
                          ),
                    trailing: Icon(Icons.chevron_right,
                        color: isDark ? Colors.white70 : Colors.black45),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserProfilePage(),
                        ),
                      );
                    },
                  ),
                  Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.black12),
                  // Notifiche solo ON/OFF
                  SwitchListTile(
                    value: _notificationsEnabled,
                    onChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                      _savePrefs();
                    },
                    secondary: Icon(Icons.notifications_none,
                        color: isDark ? Colors.white70 : Colors.black54),
                    title: Text('Notifications',
                        style: TextStyle(
                            color:
                                isDark ? Colors.white : Colors.black)),
                  ),
                  Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.black12),
                  // Dark mode toggle
                  SwitchListTile(
                    value: themeProvider.isDarkMode,
                    onChanged: (val) {
                      themeProvider.toggleTheme();
                    },
                    secondary: Icon(Icons.dark_mode_outlined,
                        color: isDark ? Colors.white70 : Colors.black54),
                    title: Text('Dark mode',
                        style: TextStyle(
                            color:
                                isDark ? Colors.white : Colors.black)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Card chat + logout
            Container(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (!isOwnProfile) ...[
                    ListTile(
                      leading: Icon(Icons.message,
                          color:
                              isDark ? Colors.white70 : Colors.black54),
                      title: Text('Chatta con questo utente',
                          style: TextStyle(
                              color:
                                  isDark ? Colors.white : Colors.black)),
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
                    Divider(
                        height: 1,
                        color:
                            isDark ? Colors.white12 : Colors.black12),
                  ],
                  ListTile(
                    leading:
                        const Icon(Icons.logout, color: Color(0xFFFF4A4A)),
                    title: const Text(
                      'Log out',
                      style: TextStyle(color: Color(0xFFFF4A4A)),
                    ),
                    onTap: () async {
                      final confirmed =
                          await _showLogoutConfirmation(context);
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
