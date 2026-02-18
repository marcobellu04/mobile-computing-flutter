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
  String _me = 'guest@local';

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    final prefs = await SharedPreferences.getInstance();
    final me = prefs.getString('user_email') ?? 'guest@local';
    if (mounted) setState(() { _me = me; });
  }

  bool _isOwner(Venue v) {
    final mioEmailPulita = _me.trim().toLowerCase();
    final ownerEmailPulita = (v.email ?? "").trim().toLowerCase();
    return mioEmailPulita == ownerEmailPulita;
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ✅ NUOVA FUNZIONE: Conferma eliminazione
  void _confirmDelete(BuildContext context, String venueId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Elimina Struttura"),
        content: const Text("Sei sicuro di voler eliminare definitivamente questa struttura? Tutti i dati andranno persi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
          TextButton(
            onPressed: () {
              // Chiamiamo il provider per eliminare la struttura
              context.read<VenueProvider>().deleteVenue(venueId);
              Navigator.pop(ctx); // Chiude il dialogo
              Navigator.pop(context); // Torna alla lista strutture
              _snack("Struttura eliminata con successo");
            },
            child: const Text("Elimina", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venueProvider = Provider.of<VenueProvider>(context);
    final current = venueProvider.venues.firstWhere(
      (v) => v.id == widget.venue.id,
      orElse: () => widget.venue,
    );

    final isOwner = _isOwner(current);

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text(current.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        // ✅ AGGIUNTO: Tasto elimina nell'appbar solo per l'owner
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context, current.id),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'venue-${current.id}',
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[300]),
                child: (current.imagePath != null && File(current.imagePath!).existsSync())
                    ? Image.file(File(current.imagePath!), fit: BoxFit.cover)
                    : const Icon(Icons.storefront, size: 100, color: Colors.white),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          current.name,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${current.capacity ?? "N/D"} posti',
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          current.address ?? "Indirizzo non disponibile",
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 10),

                  const Text(
                    "Informazioni sulla struttura",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    current.email != null 
                        ? "Contatto: ${current.email}" 
                        : "Nessuna informazione aggiuntiva disponibile.",
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),

                  const SizedBox(height: 40),

                  if (!isOwner) 
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                userEmail: _me,
                                venueEmail: current.email ?? current.id,
                                venueName: current.name,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text("CONTATTA LA STRUTTURA", 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: const Center(
                        child: Text(
                          "STAI VISUALIZZANDO LA TUA STRUTTURA",
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
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