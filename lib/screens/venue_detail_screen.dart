import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/venue.dart';
import '../providers/venue_provider.dart';
import 'chat_page.dart';

class VenueDetailScreen extends StatelessWidget {
  final Venue venue;

  const VenueDetailScreen({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    // Ascoltiamo il provider per avere dati sempre aggiornati (es. se cambia l'immagine)
    final venueProvider = Provider.of<VenueProvider>(context);
    // Troviamo la versione più recente della struttura nella lista del provider
    final current = venueProvider.venues.firstWhere(
      (v) => v.id == venue.id,
      orElse: () => venue,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(current.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMMAGINE GRANDE IN ALTO
            Hero(
              tag: 'venue-${current.id}', // Animazione fluida tra le pagine
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                ),
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
                  // 2. NOME E CAPIENZA
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

                  // 3. INDIRIZZO
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

                  // 4. DESCRIZIONE O INFO EXTRA
                  const Text(
                    "Informazioni sulla struttura",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    current.email != null 
                        ? "Contatto: ${current.email}" 
                        : "Nessuna informazione aggiuntiva disponibile per questa struttura.",
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),

                  const SizedBox(height: 40),

                  // 5. PULSANTE CHAT
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              userEmail: 'user@example.com', // Sostituisci con email reale
                              venueEmail: current.id,
                              venueName: current.name,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("CONTATTA LA STRUTTURA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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