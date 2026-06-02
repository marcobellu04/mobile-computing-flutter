import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_first_app/screens/events_requests_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User; // MODIFICA: Nasconde User di Firebase per evitare conflitti
import 'package:google_sign_in/google_sign_in.dart';
import 'user_profile_page.dart';
import 'venue_requests_page.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../providers/event_provider.dart';
import '../providers/venue_provider.dart';
import '../providers/booking_provider.dart';
import 'package:provider/provider.dart';
import 'event_detail_page.dart';
import 'venue_detail_screen.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    setState(() {
      _profileImage = File(savedPath);
    });
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .get();

    if (doc.exists && doc.data() != null) {
      setState(() {
        _user = User.fromMap(doc.data()!);
      });
      return;
    }
  } catch (e) {
    debugPrint("Errore caricamento profilo da Firestore: $e");
  }

  setState(() {
    _user = User.publicProfile(
      name: email.split('@')[0],
      surname: '',
      email: email,
    );
  });
}

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled');
    if (enabled != null) {
      setState(() {
        _notificationsEnabled = enabled;
      });
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
  }

  void _showNoRequestsMessage(String tipo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Nessuna richiesta pendente per $tipo."),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showManagementArea(BuildContext context, List<Event> events, List<Venue> venues) {
    final eventProvider = context.read<EventProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final venuesWithRequestsCount = venues.where((v) =>
      bookingProvider.requests.any((r) => r.venueEmail == v.ownerEmail && r.status == 'pending')
    ).length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text('AREA GESTIONE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 25),
            _buildManagementTile(
              context,
              icon: Icons.people_alt_outlined,
              title: "Richieste Eventi Privati",
              subtitle: "Gestisci chi vuole partecipare",
              count: eventProvider.countPendingRequestsForOwner(widget.profileUserEmail),
              onTap: () {
                Navigator.pop(context);
                _showCreatedEventsList(context, events, onlyWithRequests: true);
              },
            ),
            const SizedBox(height: 15),
            _buildManagementTile(
              context,
              icon: Icons.house_siding_rounded,
              title: "Richieste Strutture",
              subtitle: "Prenotazioni per le tue location",
              count: venuesWithRequestsCount,
              onTap: () {
                Navigator.pop(context);
                _showCreatedVenuesList(context, venues, isManagementMode: true);
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementTile(BuildContext context, {required IconData icon, required String title, required String subtitle, int count = 0, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.amber[100], child: Icon(icon, color: Colors.amber[900])),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(15)),
                child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showCreatedEventsList(BuildContext context, List<Event> events, {bool onlyWithRequests = false}) {
    final filtered = onlyWithRequests ? events.where((e) => e.pendingRequests.isNotEmpty).toList() : events;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(onlyWithRequests ? 'EVENTI CON RICHIESTE' : 'I MIEI EVENTI', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Expanded(
              child: filtered.isEmpty
                ? const Center(child: Text("Nessun evento presente", style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final e = filtered[i];
                      return ListTile(
                        leading: Icon(Icons.event, color: e.pendingRequests.isNotEmpty ? Colors.red : Colors.amber),
                        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${e.date.day}/${e.date.month}/${e.date.year}"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          if (onlyWithRequests) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => EventRequestsPage(eventId: e.id, eventName: e.name)));
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(event: e)));
                          }
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

  void _showCreatedVenuesList(BuildContext context, List<Venue> venues, {bool isManagementMode = false}) {
    final bookingProvider = context.read<BookingProvider>();
    final filtered = isManagementMode ? venues.where((v) => bookingProvider.requests.any((r) => r.venueEmail == v.ownerEmail && r.status == 'pending')).toList() : venues;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isManagementMode ? 'STRUTTURE CON RICHIESTE' : 'LE MIE STRUTTURE', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Expanded(
              child: filtered.isEmpty
                ? const Center(child: Text("Nessuna struttura presente", style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final v = filtered[i];
                      bool hasReq = bookingProvider.requests.any((r) => r.venueEmail == v.ownerEmail && r.status == 'pending');
                      return ListTile(
                        leading: Icon(Icons.business, color: hasReq ? Colors.red : Colors.amber),
                        title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(isManagementMode ? "Gestisci prenotazioni" : (v.address ?? "Senza indirizzo")),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          if (isManagementMode) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => VenueRequestsPage(venueEmail: v.ownerEmail)));
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: v)));
                          }
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

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final venueProvider = context.watch<VenueProvider>();
    final myCreatedEvents = eventProvider.events.where((e) => e.ownerEmail == widget.profileUserEmail).toList();
    final myCreatedVenues = venueProvider.venues.where((v) => v.ownerEmail == widget.profileUserEmail).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Impostazioni', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, backgroundColor: Colors.white, elevation: 0),
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
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfilePage()));
                  if (result == true) _loadUser();
                },
              ),
              const Divider(height: 1, indent: 50),
              ListTile(
                leading: const Icon(Icons.auto_awesome_motion_outlined, color: Colors.black87),
                title: const Text('I miei eventi', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCreatedEventsList(context, myCreatedEvents),
              ),
              const Divider(height: 1, indent: 50),
              ListTile(
                leading: const Icon(Icons.business_outlined, color: Colors.black87),
                title: const Text('Le mie strutture', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCreatedVenuesList(context, myCreatedVenues),
              ),
              const Divider(height: 1, indent: 50),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.amber),
                title: const Text('AREA GESTIONE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                subtitle: const Text('Gestisci solo chi ha richieste'),
                trailing: const Icon(Icons.chevron_right, color: Colors.amber),
                onTap: () => _showManagementArea(context, myCreatedEvents, myCreatedVenues),
              ),
              const Divider(height: 1, indent: 50),
              SwitchListTile(
                activeThumbColor: Colors.amber,
                secondary: const Icon(Icons.notifications_none_outlined, color: Colors.black87),
                title: const Text('Notifiche push', style: TextStyle(fontWeight: FontWeight.w500)),
                value: _notificationsEnabled,
                onChanged: (val) {
                  setState(() => _notificationsEnabled = val);
                  _savePrefs();
                },
              ),
            ]),
            const SizedBox(height: 30),
            _buildSectionCard([
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', false);
  await prefs.remove('user_email');

  try {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  } catch (_) {}

  if (mounted) Navigator.of(context).pushReplacementNamed('/login');
},
              ),
              const Divider(height: 1, indent: 50),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: const Text('Elimina Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext ctx) {
                      return AlertDialog(
                        title: const Text('Conferma Eliminazione'),
                        content: const Text('Sei sicuro di voler eliminare permanentemente il tuo account? Questa azione non può essere annullata e cancellerà anche tutti i tuoi eventi e le tue strutture.'),
                        actions: [
                          TextButton(
                            child: const Text('Annulla', style: TextStyle(color: Colors.black)),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          TextButton(
                            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final email = widget.profileUserEmail;
                              context.read<EventProvider>().deleteEventsByOwner(email);
                              context.read<VenueProvider>().deleteVenuesByOwner(email);
                              final usersString = prefs.getString('users');
                              if (usersString != null) {
                                List<dynamic> usersList = jsonDecode(usersString);
                                usersList.removeWhere((u) => u['email'].toString().toLowerCase() == email.toLowerCase());
                                await prefs.setString('users', jsonEncode(usersList));
                              }
                              await prefs.remove('user_data_$email');
                              await prefs.remove('user_image_$email');
                              await prefs.remove('user_email');
                              await prefs.setBool('isLoggedIn', false);
                              try {
                                final GoogleSignIn googleSignIn = GoogleSignIn();
                                if (await googleSignIn.isSignedIn()) {
                                  await googleSignIn.disconnect();
                                }
                                if (FirebaseAuth.instance.currentUser != null) {
                                  await FirebaseAuth.instance.currentUser?.delete();
                                }
                              } catch (_) {}
                              if (mounted) {
                                Navigator.of(ctx).pop();
                                Navigator.of(context).pushReplacementNamed('/login');
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final String name = _user != null ? '${_user!.name} ${_user!.surname}' : widget.profileUserName;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null, child: _profileImage == null ? const Icon(Icons.person) : null),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(widget.profileUserEmail, style: TextStyle(color: Colors.grey[600], fontSize: 14))])),
          const Icon(Icons.verified_user, color: Colors.amber, size: 20),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey[200]!)), child: Column(children: children));
  }
}