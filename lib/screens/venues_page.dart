import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/venue_provider.dart';
import 'venue_detail_screen.dart';

class VenuesPage extends StatelessWidget {
  const VenuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Recuperiamo la lista delle strutture dal Provider
    final venues = Provider.of<VenueProvider>(context).venues;

    if (venues.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Text(
            "Nessuna struttura disponibile", 
            style: TextStyle(color: Colors.grey[400], fontSize: 14)
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: venues.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemBuilder: (context, index) {
        final venue = venues[index];
        
        // REPLICA DELLO STILE _EventCardVertical
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey[200]!), // Bordo sottile come negli eventi
          ),
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: venue)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            
            // Leading: Immagine arrotondata o icona placeholder
            leading: Hero(
              tag: 'venue-${venue.id}',
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.amber[50], // Sfondo ambra chiaro coerente
                  borderRadius: BorderRadius.circular(12),
                ),
                child: (venue.imagePath != null && File(venue.imagePath!).existsSync())
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(venue.imagePath!), 
                          fit: BoxFit.cover
                        ),
                      )
                    : const Icon(Icons.location_city, color: Colors.amber),
              ),
            ),

            // Titolo struttura
            title: Text(
              venue.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            // Sottotitolo con icone grigie (Capienza e Indirizzo/Zona)
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("${venue.capacity ?? 'n.d.'}"),
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      venue.address ?? 'Zona n.d.',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Freccetta laterale
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ),
        );
      },
    );
  }
}