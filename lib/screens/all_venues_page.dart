import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/venue_provider.dart';
import 'venue_detail_screen.dart';

class AllVenuesPage extends StatelessWidget {
  const AllVenuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final venues = context.watch<VenueProvider>().venues;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tutte le Strutture", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: venues.length,
        itemBuilder: (context, index) {
          final venue = venues[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50, height: 50, color: Colors.blue[100],
                  child: (venue.imagePath != null && File(venue.imagePath!).existsSync())
                      ? Image.file(File(venue.imagePath!), fit: BoxFit.cover)
                      : const Icon(Icons.store, color: Colors.blue),
                ),
              ),
              title: Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(venue.address ?? "Nessun indirizzo"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: venue))),
            ),
          );
        },
      ),
    );
  }
}