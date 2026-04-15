import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile_page.dart';
import 'chat_page.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import 'package:provider/provider.dart';
import 'event_detail_page.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sei sicuro?'),
        content: const Text('Confermi di voler uscire dal tuo account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Esci', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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

  // Mostra l'elenco degli eventi creati in un menu dal basso
  void _showCreatedEventsList(BuildContext context, List<Event> events) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text('I MIEI EVENTI CREATI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.separated(
                itemCount: events.length,
                separatorBuilder: (ctx, i) => const Divider(),
                itemBuilder: (ctx, i) {
                  final e = events[i];
                  return ListTile(
                    leading: const Icon(Icons.event, color: Colors.amber),
                    title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${e.date.day}/${e.date.month}/${e.date.year}"),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.pop(context); // Chiude il menu
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(event: e)));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final String name = _user != null ? '${_user!.name} ${_user!.surname}' : widget.profileUserName;
    final String email = _user != null ? _user!.email : widget.profileUserEmail;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null 
                  ? const Icon(Icons.person, color: Colors.grey, size: 30) 
                  : null,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.verified_user, color: Colors.amber, size: 20),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwnProfile = widget.currentUserEmail == widget.profileUserEmail;
    final eventProvider = context.watch<EventProvider>();
    final myCreatedEvents = eventProvider.events
        .where((e) => e.ownerEmail == widget.profileUserEmail)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Impostazioni', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            
            const Padding(
              padding: EdgeInsets.only(left: 10, bottom: 10),
              child: Text('ACCOUNT', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            
            _buildSectionCard([
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.black87),
                title: const Text('Dati del profilo', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserProfilePage()),
                  );
                  if (result == true) _loadUser();
                },
              ),
              const Divider(height: 1, indent: 50),
              // --- NUOVO TASTO EVENTI CREATI ---
              ListTile(
                leading: const Icon(Icons.auto_awesome_motion_outlined, color: Colors.black87),
                title: const Text('Eventi creati da me', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (myCreatedEvents.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(10)),
                        child: Text('${myCreatedEvents.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _showCreatedEventsList(context, myCreatedEvents),
              ),
              const Divider(height: 1, indent: 50),
              SwitchListTile(
                activeColor: Colors.amber,
                secondary: const Icon(Icons.notifications_none_outlined, color: Colors.black87),
                title: const Text('Notifiche push', style: TextStyle(fontWeight: FontWeight.w500)),
                value: _notificationsEnabled,
                onChanged: (val) {
                  setState(() => _notificationsEnabled = val);
                  _savePrefs();
                },
              ),
            ]),

            const SizedBox(height: 25),

            const Padding(
              padding: EdgeInsets.only(left: 10, bottom: 10),
              child: Text('AZIONI', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),

            _buildSectionCard([
              if (!isOwnProfile) ...[
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
                  title: const Text('Invia un messaggio'),
                  trailing: const Icon(Icons.chevron_right),
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
                const Divider(height: 1, indent: 50),
              ],
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () async {
                  final confirmed = await _showLogoutConfirmation(context);
                  if (confirmed) await _logout(context);
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }
}