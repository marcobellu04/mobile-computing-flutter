import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../providers/event_provider.dart';

class ParticipationRequestsPage extends StatefulWidget {
  final Event event;
  final ValueChanged<Event> onEventUpdated;

  const ParticipationRequestsPage({
    Key? key,
    required this.event,
    required this.onEventUpdated,
  }) : super(key: key);

  @override
  State<ParticipationRequestsPage> createState() => _ParticipationRequestsPageState();
}

class _ParticipationRequestsPageState extends State<ParticipationRequestsPage> {
  late Event event;

  @override
  void initState() {
    super.initState();
    event = widget.event;
  }

  void _handleRequest(String userEmail, bool isAccepted) {
    setState(() {
      event.pendingRequests.remove(userEmail);
      if (isAccepted) {
        if (event.participants.length < event.maxParticipants) {
          event.participants.add(userEmail);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Richiesta di $userEmail accettata')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Limite partecipanti raggiunto')),
          );
          // Se non può accettare, mantieni l’utente in pending o gestisci diversamente
          // Qui la rimuoviamo comunque
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Richiesta di $userEmail rifiutata')),
        );
      }
      // Aggiorna evento nel provider e callback
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      eventProvider.updateEvent(event);
      widget.onEventUpdated(event);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingList = event.pendingRequests;

    return Scaffold(
      appBar: AppBar(title: Text('Richieste di partecipazione')),
      body: pendingList.isEmpty
          ? const Center(child: Text('Nessuna richiesta pendente'))
          : ListView.builder(
              itemCount: pendingList.length,
              itemBuilder: (context, index) {
                final userEmail = pendingList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: ListTile(
                    title: Text(userEmail),
                    subtitle: const Text('Richiesta di partecipazione'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: 'Accetta',
                          onPressed: () => _handleRequest(userEmail, true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Rifiuta',
                          onPressed: () => _handleRequest(userEmail, false),
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
