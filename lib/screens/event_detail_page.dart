import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event.dart';
import '../models/venue.dart';
import '../providers/event_provider.dart';
import '../providers/likes_provider.dart';
import '../providers/venue_provider.dart';
import 'chat_page.dart';
import 'external_profile_screen.dart'; 

class EventDetailPage extends StatefulWidget {
  final Event event;
  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  String _me = 'guest@local';
  int? _myAge;

  @override
  void initState() {
    super.initState();
    _loadMeAndAge();
  }

  Future<void> _loadMeAndAge() async {
    final prefs = await SharedPreferences.getInstance();
    final me = prefs.getString('user_email') ?? 'guest@local';
    final age = prefs.getInt('userAge');
    if (mounted) setState(() { _me = me; _myAge = age; });
  }

  Event _getFreshEvent(BuildContext context) {
    return context.watch<EventProvider>().events.firstWhere(
          (e) => e.id == widget.event.id,
          orElse: () => widget.event,
        );
  }

  bool _isFull(Event e) => e.participants.length >= e.maxParticipants;
  bool _isIn(Event e) => e.participants.contains(_me);
  bool _hasRequested(Event e) => e.pendingRequests.contains(_me);
  bool _isOwner(Event e) => _me.trim().toLowerCase() == e.ownerEmail.trim().toLowerCase();

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool _passesAgeRestriction(Event e, int age) {
    if (e.ageRestrictionType == AgeRestrictionType.none) return true;
    if (e.ageRestrictionValue == null) return true;
    if (e.ageRestrictionType == AgeRestrictionType.over) return age >= e.ageRestrictionValue!;
    if (e.ageRestrictionType == AgeRestrictionType.under) return age <= e.ageRestrictionValue!;
    return true;
  }

  Future<int?> _askAgeDialog() async {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inserisci la tua età'),
        content: TextField(controller: controller, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)), child: const Text('Salva')),
        ],
      ),
    );
  }

  Future<void> _handleJoinAction(Event current) async {
    if (current.ageRestrictionType != AgeRestrictionType.none && _myAge == null) {
      final age = await _askAgeDialog();
      if (age == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userAge', age);
      setState(() => _myAge = age);
    }
    if (_myAge != null && !_passesAgeRestriction(current, _myAge!)) {
      _snack("L'evento ha restrizioni di età che non rispetti.");
      return;
    }
    final provider = context.read<EventProvider>();
    if (current.listType == ListType.open) {
      provider.joinEvent(current.id, _me);
      _snack('Iscrizione completata!');
    } else {
      provider.requestToJoin(current.id, _me);
      _snack('Richiesta inviata!');
    }
  }

  Future<void> _openInGoogleMaps(String address) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _snack('Impossibile aprire le mappe.');
    }
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.amber, size: 22),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _getFreshEvent(context);
    final likesProvider = context.watch<LikesProvider>();
    final venueProvider = context.watch<VenueProvider>();
    
    final isOwner = _isOwner(current);
    final inEvent = _isIn(current);
    final requested = _hasRequested(current);
    final full = _isFull(current);
    final isLiked = likesProvider.isLiked(current.id);

    final dateStr = "${current.date.day}/${current.date.month}/${current.date.year}";
    final canSeeAddress = inEvent || isOwner;

    Venue? linkedVenue;
    if (current.venueId != null) {
      try { linkedVenue = venueProvider.venues.firstWhere((v) => v.id == current.venueId); } catch(_) {}
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'event-${current.id}',
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.45,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                    child: (current.imagePath != null && File(current.imagePath!).existsSync())
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                            child: Image.file(File(current.imagePath!), fit: BoxFit.cover),
                          )
                        : const Icon(Icons.image, size: 100, color: Colors.grey),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(current.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: current.listType == ListType.open ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          current.listType == ListType.open ? 'LISTA APERTA' : 'LISTA PRIVATA',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: current.listType == ListType.open ? Colors.green : Colors.red),
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildInfoTile(Icons.calendar_today_rounded, dateStr, "Data dell'evento"),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: canSeeAddress && current.fullAddress != null ? () => _openInGoogleMaps(current.fullAddress!) : null,
                        child: _buildInfoTile(
                          Icons.location_on_rounded, 
                          current.zone ?? "Zona n.d.", 
                          canSeeAddress ? (current.fullAddress ?? "Indirizzo non presente") : "Visibile dopo iscrizione"
                        ),
                      ),
                      const Divider(height: 50),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle("Partecipanti"),
                          Text(
                            '${current.participants.length} / ${current.maxParticipants}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14),
                          ),
                        ],
                      ),
                      if (current.participants.isEmpty)
                        const Text("Nessuno si è ancora iscritto.", style: TextStyle(color: Colors.grey))
                      else
                        SizedBox(
                          height: 45,
                          child: Stack(
                            children: [
                              ...List.generate(
                                current.participants.length > 5 ? 5 : current.participants.length,
                                (index) {
                                  final userEmail = current.participants[index];
                                  return Positioned(
                                    left: index * 28.0, 
                                    child: GestureDetector(
                                      onTap: isOwner 
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ExternalProfileScreen(email: userEmail),
                                              ),
                                            );
                                          }
                                        : null, 
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2.5),
                                        ),
                                        child: CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.amber[200],
                                          child: Text(
                                            userEmail[0].toUpperCase(),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      _buildSectionTitle("Descrizione"),
                      Text(current.description ?? "Nessuna descrizione fornita.", 
                        style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5)),

                      _buildSectionTitle("Organizzatore"),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ExternalProfileScreen(email: current.ownerEmail)),
                          );
                        },
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber[100], 
                            child: Text(current.ownerName[0].toUpperCase(), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))
                          ),
                          title: Text("${current.ownerName} ${current.ownerSurname}", style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(current.ownerEmail),
                          trailing: !isOwner 
                            ? IconButton(
                                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.amber),
                                onPressed: () {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(
                                      builder: (_) => ChatPage(userEmail: _me, venueEmail: current.ownerEmail, venueName: current.ownerName)
                                    )
                                  );
                                },
                              )
                            : null,
                        ),
                      ),
                      
                      if (linkedVenue != null) ...[
                        const SizedBox(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: linkedVenue.imagePath != null && File(linkedVenue.imagePath!).existsSync()
                              ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(linkedVenue.imagePath!), width: 50, height: 50, fit: BoxFit.cover))
                              : Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.business, color: Colors.amber)),
                          title: Text(linkedVenue.name),
                          subtitle: Text(linkedVenue.address ?? "Struttura ospitante"),
                        ),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // BARRA SUPERIORE (BACK E LIKE)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                    ),
                  ),
                  
                  // IL CUORE APPARE SOLO SE NON SEI IL PROPRIETARIO
                  if (!isOwner)
                    GestureDetector(
                      onTap: () => likesProvider.toggleLike(_me, current.id),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded, 
                          color: isLiked ? Colors.red : Colors.black, 
                          size: 20
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (!isOwner)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(25, 15, 25, 25),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                ),
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (inEvent || requested || full) ? null : () => _handleJoinAction(current),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: Text(
                      inEvent ? 'SEI GIÀ ISCRITTO' : (requested ? 'RICHIESTA INVIATA' : (full ? 'EVENTO PIENO' : 'PARTECIPA')),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}