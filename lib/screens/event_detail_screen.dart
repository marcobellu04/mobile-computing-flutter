import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';
import '../providers/event_provider.dart';
import 'chat_page.dart';
import 'external_profile_screen.dart';

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

    if (current.listType == ListType.open) {
      provider.joinEvent(current.id, _me);
      _snack('Partecipazione confermata!');
    } else {
      if (_hasRequested(current)) return;
      provider.requestToJoin(current.id, _me);
      _snack('Richiesta inviata!');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<EventProvider>().events.firstWhere((e) => e.id == widget.event.id, orElse: () => widget.event);
    final dateStr = "${current.date.day}/${current.date.month}/${current.date.year}";
    final isFull = _isFull(current);
    final alreadyIn = _isIn(current);
    final isOwner = _isOwner(current);
    final hasRequested = _hasRequested(current);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dettaglio Evento'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context, current.id),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero, 
        children: [
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
                const SizedBox(height: 25),
                
                // --- NUOVA SEZIONE PARTECIPANTI CON AVATAR ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Partecipanti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${current.participants.length} / ${current.maxParticipants}', 
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                if (current.participants.isEmpty)
                  const Text("Nessun partecipante ancora", style: TextStyle(color: Colors.grey))
                else
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: current.participants.length,
                      itemBuilder: (context, index) => _ParticipantAvatar(email: current.participants[index]),
                    ),
                  ),
                
                const SizedBox(height: 20),

                // --- SEZIONE SPECIALE OWNER: RICHIESTE ---
                if (isOwner && current.pendingRequests.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text('RICHIESTE DA APPROVARE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 10),
                  ...current.pendingRequests.map((email) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    color: Colors.grey[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(email, style: const TextStyle(fontSize: 14)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => context.read<EventProvider>().approveRequest(current.id, email)),
                          IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => context.read<EventProvider>().rejectRequest(current.id, email)),
                        ],
                      ),
                    ),
                  )).toList(),
                ],

                const SizedBox(height: 30),

                // --- SEZIONE PULSANTI ---
                if (!isOwner) ...[
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
                              venueEmail: current.ownerEmail,
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
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (alreadyIn || hasRequested || isFull) ? null : _joinOrRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: Text(
                        alreadyIn ? 'SEI GIÀ ISCRITTO' : 
                        hasRequested ? 'RICHIESTA INVIATA' :
                        (isFull ? 'EVENTO PIENO' : (current.listType == ListType.open ? 'PARTECIPA ORA' : 'INVIA RICHIESTA')), 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: const Center(
                      child: Text("STAI GESTENDO IL TUO EVENTO", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET PER L'AVATAR DEL PARTECIPANTE ---
class _ParticipantAvatar extends StatelessWidget {
  final String email;
  const _ParticipantAvatar({required this.email});

  @override
  Widget build(BuildContext context) {
    // Estraiamo un nome dall'email per ora (es: mario.rossi@gmail.com -> Mario)
    String displayName = email.split('@')[0].split('.')[0];
    displayName = displayName[0].toUpperCase() + displayName.substring(1);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExternalProfileScreen(email: email)),
        );
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.amber[100],
              child: Text(displayName[0], style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 5),
            Text(
              displayName,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

