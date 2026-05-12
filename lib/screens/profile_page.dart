import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile_page.dart';
import 'chat_page.dart';
import 'venue_requests_page.dart'; 
import '../models/user.dart';
import '../models/event.dart';
import '../models/venue.dart'; 
import '../providers/event_provider.dart';
import '../providers/venue_provider.dart'; 
import 'package:provider/provider.dart';
import 'event_detail_page.dart';
import 'venue_detail_screen.dart'; 
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

  // --- AREA GESTIONE MODAL ---
  void _showManagementArea(BuildContext context, List<Event> events, List<Venue> venues) {
    final eventProvider = context.read<EventProvider>();
    
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
            
            // 1. Gestione Richieste Eventi Privati
            _buildManagementTile(
              context,
              icon: Icons. people_alt_outlined,
              title: "Richieste Eventi Privati",
              subtitle: "Approvazioni per i tuoi eventi",
              count: eventProvider.countPendingRequestsForOwner(widget.profileUserEmail),
              onTap: () {
                Navigator.pop(context);
                _showCreatedEventsList(context, events); // Mostra la lista eventi per gestire le richieste
              },
            ),
            
            const SizedBox(height: 15),
            
            // 2. Gestione Richieste Strutture (Ti fa scegliere QUALE struttura gestire)
            _buildManagementTile(
              context,
              icon: Icons.house_siding_rounded,
              title: "Richieste Strutture",
              subtitle: "Gestisci prenotazioni per singola struttura",
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
            const Text('I MIEI EVENTI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.separated(
                itemCount: events.length,
                separatorBuilder: (ctx, i) => const Divider(),
                itemBuilder: (ctx, i) {
                  final e = events[i];
                  final hasRequests = e.pendingRequests.isNotEmpty;
                  return ListTile(
                    leading: Icon(Icons.event, color: hasRequests ? Colors.red : Colors.amber),
                    title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${e.date.day}/${e.date.month}/${e.date.year}"),
                    trailing: hasRequests 
                      ? Text('${e.pendingRequests.length} nuove', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                      : const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
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

  // MODIFICA: Aggiunto flag isManagementMode per distinguere tra "Vedi Dettaglio" e "Gestisci Richieste"
  void _showCreatedVenuesList(BuildContext context, List<Venue> venues, {bool isManagementMode = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isManagementMode ? 'QUALE STRUTTURA VUOI GESTIRE?' : 'LE MIE STRUTTURE', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.separated(
                itemCount: venues.length,
                separatorBuilder: (ctx, i) => const Divider(),
                itemBuilder: (ctx, i) {
                  final v = venues[i];
                  return ListTile(
                    leading: const Icon(Icons.business, color: Colors.amber),
                    title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(v.address ?? ""),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      if (isManagementMode) {
                        // Se siamo in modalità gestione, andiamo alla pagina delle richieste SPECIFICA per questa struttura
                        Navigator.push(context, MaterialPageRoute(builder: (_) => VenueRequestsPage(venueEmail: widget.profileUserEmail)));
                      } else {
                        // Altrimenti solo dettaglio
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
    final bool isOwnProfile = widget.currentUserEmail == widget.profileUserEmail;
    final eventProvider = context.watch<EventProvider>();
    final myCreatedEvents = eventProvider.events.where((e) => e.ownerEmail == widget.profileUserEmail).toList();
    final venueProvider = context.watch<VenueProvider>();
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
              // 1. DATI PROFILO
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

              // 2. I MIEI EVENTI (Rimane qui come volevi)
              ListTile(
                leading: const Icon(Icons.auto_awesome_motion_outlined, color: Colors.black87),
                title: const Text('I miei eventi', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (eventProvider.countPendingRequestsForOwner(widget.profileUserEmail) > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('${eventProvider.countPendingRequestsForOwner(widget.profileUserEmail)}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _showCreatedEventsList(context, myCreatedEvents),
              ),
              const Divider(height: 1, indent: 50),

              // 3. LE MIE STRUTTURE (Rimane qui come volevi)
              ListTile(
                leading: const Icon(Icons.business_outlined, color: Colors.black87),
                title: const Text('Le mie strutture', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCreatedVenuesList(context, myCreatedVenues),
              ),
              const Divider(height: 1, indent: 50),

              // 4. AREA GESTIONE (SOTTO I PRECEDENTI)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.amber),
                title: const Text('AREA GESTIONE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                subtitle: const Text('Gestisci richieste e prenotazioni'),
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
            // ... (Resto del buildHeader, logout etc rimane uguale)
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---
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