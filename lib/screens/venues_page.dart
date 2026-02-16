import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/venue_provider.dart';
import 'venue_detail_screen.dart'; // Assicurati che il percorso sia corretto

class VenuesPage extends StatelessWidget {
  const VenuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Recuperiamo la lista delle strutture dal Provider
    final venues = Provider.of<VenueProvider>(context).venues;

    if (venues.isEmpty) {
      return const Center(
        child: Text(
          "Nessuna struttura disponibile",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: venues.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final venue = venues[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            // Azione al click: apre il dettaglio
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VenueDetailScreen(venue: venue),
                ),
              );
            },
            // IMMAGINE ARROTONDATA CON ANIMAZIONE HERO
            leading: Hero(
              tag: 'venue-${venue.id}', // Identificativo unico per l'animazione
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: (venue.imagePath != null && File(venue.imagePath!).existsSync())
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(venue.imagePath!), 
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                        ),
                      )
                    : const Icon(Icons.location_city, color: Colors.amber, size: 30),
              ),
            ),
            title: Text(
              venue.name, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Capienza: ${venue.capacity ?? "N/D"} persone',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ),
        );
      },
    );
  }
}