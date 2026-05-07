import 'dart:io'; // NECESSARIO
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/venue_provider.dart';
import 'chat_page.dart';

class VenueListPage extends StatelessWidget {
  const VenueListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final venues = Provider.of<VenueProvider>(context).venues;

    return Scaffold(
      appBar: AppBar(title: const Text('Seleziona una struttura')),
      body: venues.isEmpty 
        ? const Center(child: Text("Nessuna struttura trovata"))
        : ListView.builder(
            itemCount: venues.length,
            itemBuilder: (context, index) {
              final venue = venues[index];
              return ListTile(
                // ANTEPRIMA IMMAGINE CIRCOLARE
                leading: CircleAvatar(
                  backgroundColor: Colors.amber[100],
                  backgroundImage: (venue.imagePath != null && File(venue.imagePath!).existsSync())
                      ? FileImage(File(venue.imagePath!))
                      : null,
                  child: (venue.imagePath == null || !File(venue.imagePath!).existsSync())
                      ? const Icon(Icons.storefront, color: Colors.amber)
                      : null,
                ),
                title: Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Capienza: ${venue.capacity ?? "N/D"}'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      const userEmail = 'user@example.com'; // Da sostituire con email reale
                      return AlertDialog(
                        title: Text('Inizia chat con ${venue.name}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annulla'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    userEmail: userEmail,
                                    venueEmail: venue.id,
                                    venueName: venue.name,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Chat'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
    );
  }
}