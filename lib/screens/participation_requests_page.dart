import 'package:flutter/material.dart';

import '../models/event.dart';

class ParticipationRequestsPage extends StatefulWidget {
  final Event event;
  final void Function(Event) onEventUpdated;

  const ParticipationRequestsPage({
    super.key,
    required this.event,
    required this.onEventUpdated,
  });

  @override
  State<ParticipationRequestsPage> createState() =>
      _ParticipationRequestsPageState();
}

class _ParticipationRequestsPageState extends State<ParticipationRequestsPage> {
  late Event event;

  @override
  void initState() {
    super.initState();
    event = widget.event;
  }

  void _acceptRequest(String email) {
    setState(() {
      event.pendingRequests.remove(email);
      event.participants.add(email);
    });
    widget.onEventUpdated(event);
  }

  void _rejectRequest(String email) {
    setState(() {
      event.pendingRequests.remove(email);
    });
    widget.onEventUpdated(event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Richieste partecipazione: ${event.name}')),
      body: event.pendingRequests.isEmpty
          ? const Center(child: Text('Nessuna richiesta in sospeso'))
          : ListView.builder(
              itemCount: event.pendingRequests.length,
              itemBuilder: (context, index) {
                final email = event.pendingRequests[index];
                return ListTile(
                  title: Text(email),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptRequest(email),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rejectRequest(email),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
