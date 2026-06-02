import 'package:flutter/material.dart';
import 'package:my_first_app/screens/add_event.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';

class UserBookingsPage extends StatelessWidget {
  final String userEmail;

  const UserBookingsPage({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final mySentRequests = bookingProvider.requests
        .where((r) => r.senderEmail.trim().toLowerCase() == userEmail.trim().toLowerCase())
        .toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Le mie Prenotazioni")),
      body: mySentRequests.isEmpty
          ? const Center(child: Text("Non hai ancora inviato richieste."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mySentRequests.length,
              itemBuilder: (context, index) {
                final req = mySentRequests[index];
                return Card(
                  child: ListTile(
                    title: Text(req.venueName),
                    subtitle: Text("${req.date} - Stato: ${req.status.toUpperCase()}"),
                    trailing: req.status == 'accepted'
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => AddEventScreen(
                                  ownerEmail: req.senderEmail,
                                  ownerName: req.senderEmail.split('@')[0],
                                  ownerSurname: "",
                                  approvedVenueName: req.venueName,
                                  approvedVenueAddress: req.venueAddress, // Passato dal Provider!
                                ),
                              ));
                            },
                            child: const Text("CREA EVENTO", style: TextStyle(color: Colors.black, fontSize: 10)),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}