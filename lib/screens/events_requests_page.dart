import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
// Importa la pagina del profilo esterno se vuoi poter cliccare sulla persona
// import 'external_profile_screen.dart'; 

class EventRequestsPage extends StatelessWidget {
  final String eventId;
  final String eventName;

  const EventRequestsPage({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  Widget build(BuildContext context) {
    // Usiamo watch per reagire in tempo reale quando approviamo/rifiutiamo
    final eventProvider = context.watch<EventProvider>();
    
    // Recuperiamo l'evento aggiornato dal provider
    final currentEvent = eventProvider.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception("Evento non trovato"),
    );
    
    final requests = currentEvent.pendingRequests;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Richieste: $eventName", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: requests.isEmpty
          ? const Center(child: Text("Tutte le richieste sono state gestite."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final userEmail = requests[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber[100],
                      child: Text(userEmail[0].toUpperCase(), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(userEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Vorrebbe partecipare"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tasto ACCETTA
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                          onPressed: () => eventProvider.approveRequest(eventId, userEmail),
                        ),
                        // Tasto RIFIUTA
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}