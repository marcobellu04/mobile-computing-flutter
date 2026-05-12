import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';

class VenueRequestsPage extends StatelessWidget {
  final String venueEmail; // L'email del locale loggato

  const VenueRequestsPage({super.key, required this.venueEmail});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final myRequests = bookingProvider.requests
        .where((r) => r.venueEmail.trim().toLowerCase() == venueEmail.trim().toLowerCase())
        .toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Richieste Ricevute")),
      body: myRequests.isEmpty
          ? const Center(child: Text("Nessuna richiesta ricevuta."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myRequests.length,
              itemBuilder: (context, index) {
                final req = myRequests[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: const EdgeInsets.only(bottom: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Da: ${req.senderEmail}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Divider(),
                        Text("Data: ${req.date} - ${req.timeRange}"),
                        Text("Persone: ${req.peopleCount}"),
                        if (req.message.isNotEmpty) Text("Note: ${req.message}"),
                        const SizedBox(height: 15),
                        if (req.status == 'pending')
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () => bookingProvider.updateRequestStatus(req.id, 'accepted'),
                                  child: const Text("ACCETTA", style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => bookingProvider.updateRequestStatus(req.id, 'rejected'),
                                  child: const Text("RIFIUTA", style: TextStyle(color: Colors.red)),
                                ),
                              ),
                            ],
                          )
                        else
                          Text("STATO: ${req.status.toUpperCase()}", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: req.status == 'accepted' ? Colors.green : Colors.red)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}