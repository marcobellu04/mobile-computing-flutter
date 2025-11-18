import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/venue.dart';
import '../providers/venue_provider.dart';
import 'chat_page.dart';

class VenueListPage extends StatelessWidget {
  const VenueListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final venues = Provider.of<VenueProvider>(context).venues;

    return Scaffold(
      appBar: AppBar(title: const Text('Seleziona una struttura')),
      body: ListView.builder(
        itemCount: venues.length,
        itemBuilder: (context, index) {
          final venue = venues[index];
          return ListTile(
            title: Text(venue.name),
            subtitle: Text('Capienza: ${venue.capacity}'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  final userEmail = 'user@example.com'; // Da sostituire con email reale da SharedPreferences
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
                                venueEmail: venue.id,  // Uso ID come identificatore unico
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
