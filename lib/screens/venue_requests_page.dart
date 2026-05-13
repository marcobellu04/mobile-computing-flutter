import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../providers/message_provider.dart'; // Aggiunto import
import '../models/message.dart';           // Aggiunto import

class VenueRequestsPage extends StatelessWidget {
  final String venueEmail;

  const VenueRequestsPage({super.key, required this.venueEmail});

  // Funzione di supporto per gestire l'azione e inviare il messaggio
  void _processRequest(BuildContext context, dynamic req, String newStatus) {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);

    // 1. Aggiorna lo stato della richiesta
    bookingProvider.updateRequestStatus(req.id, newStatus);

    // 2. Prepara il testo del messaggio
    String notifyText = newStatus == 'accepted'
        ? "✅ La tua richiesta per la struttura '${req.venueName}' è stata ACCETTATA!"
        : "❌ Mi dispiace, la tua richiesta per la struttura '${req.venueName}' è stata RIFIUTATA.";

    // 3. Invia il messaggio automatico
    final autoMessage = Message(
      senderEmail: req.venueEmail,   // La struttura invia
      receiverEmail: req.senderEmail, // L'utente riceve
      senderName: req.venueName,
      receiverName: req.senderEmail.split('@')[0],
      text: notifyText,
      timestamp: DateTime.now(),
      isRead: false,
    );

    messageProvider.sendMessage(autoMessage);
  }

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
                                  // Chiamata alla nuova funzione
                                  onPressed: () => _processRequest(context, req, 'accepted'),
                                  child: const Text("ACCETTA", style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  // Chiamata alla nuova funzione
                                  onPressed: () => _processRequest(context, req, 'rejected'),
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