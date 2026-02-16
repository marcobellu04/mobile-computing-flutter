import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';
import '../providers/event_provider.dart';
import 'chat_page.dart'; // Assicurati che il percorso sia corretto

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
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

  Event _fresh(BuildContext context) => context.read<EventProvider>().events.firstWhere((e) => e.id == widget.event.id, orElse: () => widget.event);
  bool _isFull(Event e) => e.participants.length >= e.maxParticipants;
  bool _isIn(Event e) => e.participants.contains(_me);
  bool _hasRequested(Event e) => e.pendingRequests.contains(_me);
  
  bool _isOwner(Event e) {
    final mioEmailPulita = _me.trim().toLowerCase();
    final ownerEmailPulita = (e.ownerEmail).trim().toLowerCase();
    return mioEmailPulita == ownerEmailPulita;
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _confirmDelete(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Elimina Evento"),
        content: const Text("Sei sicuro di voler eliminare definitivamente questo evento?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
          TextButton(
            onPressed: () {
              context.read<EventProvider>().deleteEvent(eventId);
              Navigator.pop(ctx);
              Navigator.pop(context);
              _snack("Evento eliminato con successo");
            },
            child: const Text("Elimina", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _joinOrRequest() async {
    final provider = context.read<EventProvider>();
    final current = _fresh(context);
    if (_isIn(current)) return;
    if (_isFull(current)) { _snack('Evento pieno'); return; }

    List<String> newParticipants = [...current.participants];
    List<String> newRequests = [...current.pendingRequests];

    if (current.listType == ListType.open) {
      newParticipants.add(_me);
      _snack('Partecipazione confermata!');
    } else {
      if (_hasRequested(current)) return;
      newRequests.add(_me);
      _snack('Richiesta inviata!');
    }

    provider.updateEvent(Event(
      id: current.id, name: current.name, description: current.description,
      date: current.date, ownerEmail: current.ownerEmail, ownerName: current.ownerName,
      ownerSurname: current.ownerSurname, maxParticipants: current.maxParticipants,
      participants: newParticipants, pendingRequests: newRequests,
      listType: current.listType, venueId: current.venueId, fullAddress: current.fullAddress,
      ageRestrictionType: current.ageRestrictionType, ageRestrictionValue: current.ageRestrictionValue,
      zone: current.zone,
      imagePath: current.imagePath, // ✅ IMPORTANTE: Mantieni il percorso immagine
    ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<EventProvider>().events.firstWhere((e) => e.id == widget.event.id, orElse: () => widget.event);
    final dateStr = "${current.date.day}/${current.date.month}/${current.date.year}";
    final isFull = _isFull(current);
    final alreadyIn = _isIn(current);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dettaglio Evento'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (_isOwner(current))
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context, current.id),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero, // Zero padding per far arrivare l'immagine ai bordi
        children: [
          // ✅ NUOVA SEZIONE: FOTO EVENTO
          Hero(
            tag: 'event-${current.id}',
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200]),
              child: (current.imagePath != null && File(current.imagePath!).existsSync())
                  ? Image.file(File(current.imagePath!), fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 80, color: Colors.grey),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(current.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(dateStr),
                    const SizedBox(width: 20),
                    const Icon(Icons.location_on, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(current.zone ?? 'Zona n.d.'),
                  ],
                ),
                const SizedBox(height: 25),
                const Text('Descrizione', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(current.description ?? 'Nessuna descrizione.', style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.4)),
                const SizedBox(height: 20),
                
                // BOX PARTECIPANTI
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Partecipanti', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${current.participants.length} / ${current.maxParticipants}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // ✅ NUOVO TASTO: CONTATTA ORGANIZZATORE
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            userEmail: _me,
                            venueEmail: current.ownerEmail, // Email dell'organizzatore
                            venueName: "${current.ownerName} ${current.ownerSurname}",
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text("CONTATTA ORGANIZZATORE"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: const BorderSide(color: Colors.amber),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // TASTO PARTECIPA
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _joinOrRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: Text(alreadyIn ? 'SEI GIÀ ISCRITTO' : (isFull ? 'EVENTO PIENO' : 'PARTECIPA ORA'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}