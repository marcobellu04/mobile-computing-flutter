import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import 'add_event.dart';

class UserRequestsPage extends StatelessWidget {
  final String userEmail;

  const UserRequestsPage({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    // Filtriamo le richieste fatte dall'utente corrente
    final myRequests = bookingProvider.requests
        .where((r) => r.senderEmail == userEmail)
        .toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Le mie richieste")),
      body: myRequests.isEmpty
          ? const Center(child: Text("Non hai ancora fatto richieste."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myRequests.length,
              itemBuilder: (context, index) {
                final req = myRequests[index];
                final isAccepted = req.status == 'accepted';

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  margin: const EdgeInsets.only(bottom: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Struttura: ${req.venueName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Stato: ${req.status.toUpperCase()}", 
                          style: TextStyle(color: isAccepted ? Colors.green : Colors.orange)),
                        const Divider(),
                        if (isAccepted)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEventScreen(
                                      ownerEmail: userEmail,
                                      ownerName: "Il tuo Nome", // Da recuperare dal profilo
                                      ownerSurname: "",
                                      approvedVenueName: req.venueName,
                                      approvedVenueAddress: "Indirizzo pre-approvato", 
                                    ),
                                  ),
                                );
                              },
                              child: const Text("CREA EVENTO ORA", style: TextStyle(color: Colors.black)),
                            ),
                          )
                        else
                          const Text("Potrai creare l'evento quando il gestore approverà."),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}