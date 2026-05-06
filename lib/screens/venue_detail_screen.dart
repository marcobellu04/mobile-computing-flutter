import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/venue.dart';
import '../providers/venue_provider.dart';
import 'chat_page.dart';

class VenueDetailScreen extends StatefulWidget {
  final Venue venue;
  const VenueDetailScreen({super.key, required this.venue});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  String _me = '';

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _me = prefs.getString('user_email') ?? '';
    });
  }

  bool _isOwner(Venue v) {
  if (_me.isEmpty) return false;
  // Aggiungi un controllo null-safe preventivo
  final String owner = v.ownerEmail ?? ''; 
  return _me.trim().toLowerCase() == owner.trim().toLowerCase();
}

  @override
  Widget build(BuildContext context) {
    final current = context.watch<VenueProvider>().venues.firstWhere(
      (v) => v.id == widget.venue.id,
      orElse: () => widget.venue,
    );

    final bool isOwner = _isOwner(current);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                context.read<VenueProvider>().deleteVenue(current.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: 'venue-${current.id}',
              child: Container(
                height: 300, width: double.infinity, color: Colors.grey[300],
                child: (current.imagePath != null && File(current.imagePath!).existsSync())
                    ? Image.file(File(current.imagePath!), fit: BoxFit.cover)
                    : const Icon(Icons.storefront, size: 80),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(current.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(current.address ?? "No address", style: TextStyle(color: Colors.grey[600])),
                  const Divider(height: 40),
                  const Text("Descrizione", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(current.description ?? "Nessuna descrizione."),
                  const SizedBox(height: 20),
                  if (current.phone != null)
                    ListTile(
                      leading: const Icon(Icons.phone, color: Colors.amber),
                      title: Text(current.phone!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  const SizedBox(height: 40),
                  
                  // LOGICA TASTO DINAMICO
                  if (!isOwner) 
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text("CONTATTA LA STRUTTURA"),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(
                            userEmail: _me,
                            venueEmail: current.ownerEmail, // Chat con il proprietario
                            venueName: current.name,
                          )));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                      child: const Center(child: Text("GESTISCI LA TUA STRUTTURA", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}