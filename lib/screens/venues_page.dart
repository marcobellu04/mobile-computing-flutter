import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/venue_provider.dart';

class VenuesPage extends StatelessWidget {
  const VenuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final venues = Provider.of<VenueProvider>(context).venues;

    if (venues.isEmpty) {
      return const Center(child: Text("Nessuna struttura disponibile"));
    }

    return ListView.builder(
      itemCount: venues.length,
      itemBuilder: (context, index) {
        final venue = venues[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(venue.name),
            subtitle: Text('Capienza: ${venue.capacity} persone'),
          ),
        );
      },
    );
  }
}
