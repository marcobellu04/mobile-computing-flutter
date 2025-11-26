import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';
import '../screens/other_user_profile_page.dart';
import '../screens/participation_requests_page.dart';
import '../providers/event_provider.dart';
import '../providers/message_provider.dart';

class EventDetailPage extends StatefulWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  String? userEmail;
  late Event event;

  @override
  void initState() {
    super.initState();
    event = widget.event;
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('user_email');
      // Aggiorna anche il provider messaggi con l'utente corrente
      if (userEmail != null) {
        final messageProvider = Provider.of<MessageProvider>(context, listen: false);
        messageProvider.setCurrentUserEmail(userEmail!);
      }
    });
  }

  bool get isParticipant {
    if (userEmail == null) return false;
    return event.participants.contains(userEmail);
  }

  bool get isOwner {
    return (userEmail != null && userEmail == event.ownerEmail);
  }

  bool get hasPendingRequest {
    if (userEmail == null) return false;
    return event.pendingRequests.contains(userEmail);
  }

  void _toggleParticipation() {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    setState(() {
      if (isParticipant) {
        event.participants.remove(userEmail);
        event.pendingRequests.remove(userEmail);
      } else {
        if (event.listType == ListType.open) {
          if (event.participants.length < event.maxParticipants) {
            event.participants.add(userEmail!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Posti esauriti")),
            );
          }
        } else {
          if (!event.pendingRequests.contains(userEmail!)) {
            event.pendingRequests.add(userEmail!);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Richiesta inviata, attendi approvazione")),
            );
          }
        }
      }
      eventProvider.updateEvent(event);
    });
  }

  void _manageRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParticipationRequestsPage(
          event: event,
          onEventUpdated: (updatedEvent) {
            final eventProvider = Provider.of<EventProvider>(context, listen: false);
            eventProvider.updateEvent(updatedEvent);
            setState(() {
              event = updatedEvent;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = Provider.of<MessageProvider>(context);
    final currentUserEmail = messageProvider.currentUserEmail;

    return Scaffold(
      appBar: AppBar(title: Text(event.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Data: ${event.date.day}/${event.date.month}/${event.date.year}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Descrizione: ${event.description ?? 'Nessuna descrizione'}'),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                if (event.ownerEmail != currentUserEmail) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtherUserProfilePage(
                        userEmail: event.ownerEmail,
                        userName: event.ownerEmail.split('@').first, // O vero nome se disponibile
                      ),
                    ),
                  );
                }
              },
              child: Text(
                "Creatore: ${event.ownerEmail.split('@').first}",
                style: TextStyle(
                  decoration: event.ownerEmail != currentUserEmail
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  color: event.ownerEmail != currentUserEmail
                      ? Colors.lightBlueAccent
                      : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Partecipanti: ${event.participants.length} / ${event.maxParticipants}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (isParticipant && event.fullAddress != null)
              Text('Indirizzo completo: ${event.fullAddress}')
            else
              const Text('Indirizzo completo visibile solo ai partecipanti'),
            const SizedBox(height: 20),
            if (isOwner) ...[
              ElevatedButton(
                onPressed: _manageRequests,
                child: const Text('Gestisci richieste partecipazione'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: userEmail == null
                    ? null
                    : userEmail == event.ownerEmail ? null : _toggleParticipation,
                child: Text(
                  isParticipant
                      ? 'Non partecipo più'
                      : event.listType == ListType.open
                      ? 'Partecipo'
                      : hasPendingRequest
                      ? 'Richiesta inviata'
                      : 'Partecipo',
                ),
              ),
              const SizedBox(height: 12),
              if (currentUserEmail != null &&
                  currentUserEmail != event.ownerEmail)
                ElevatedButton.icon(
                  icon: const Icon(Icons.message),
                  label: const Text('Chatta con il creatore'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OtherUserProfilePage(
                          userEmail: event.ownerEmail,
                          userName: event.ownerEmail.split('@').first,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
