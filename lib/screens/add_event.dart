import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';
import '../models/venue.dart';
import '../providers/event_provider.dart';
import '../providers/venue_provider.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController zoneController = TextEditingController();
  final TextEditingController maxParticipantsController = TextEditingController();

  DateTime? selectedDate;
  Venue? selectedVenue;
  ListType selectedListType = ListType.open;

  @override
  Widget build(BuildContext context) {
    final venueProvider = Provider.of<VenueProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Aggiungi Evento")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nome evento"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Descrizione"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: zoneController,
              decoration: const InputDecoration(labelText: "Zona (visibile a tutti)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: maxParticipantsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Numero massimo partecipanti"),
            ),
            const SizedBox(height: 10),
            DropdownButton<ListType>(
              value: selectedListType,
              onChanged: (value) {
                setState(() {
                  selectedListType = value ?? ListType.open;
                });
              },
              items: const [
                DropdownMenuItem(
                  value: ListType.open,
                  child: Text('Lista aperta (partecipazione immediata)'),
                ),
                DropdownMenuItem(
                  value: ListType.closed,
                  child: Text('Lista chiusa (richiesta di partecipazione)'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButton<Venue>(
              hint: const Text("Seleziona struttura (opzionale)"),
              value: selectedVenue,
              items: venueProvider.venues
                  .map((venue) => DropdownMenuItem<Venue>(
                        value: venue,
                        child: Text(venue.name),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedVenue = value;
                });
              },
            ),

            const SizedBox(height: 30),

            // Bottone "Aggiungi Evento" isolato e in fondo
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    zoneController.text.isEmpty ||
                    maxParticipantsController.text.isEmpty ||
                    selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Compila tutti i campi obbligatori")),
                  );
                  return;
                }

                final prefs = await SharedPreferences.getInstance();
                final ownerEmail = prefs.getString('user_email');

                if (ownerEmail == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Devi fare login per creare un evento")),
                  );
                  return;
                }

                final newEvent = Event(
                  name: nameController.text,
                  date: selectedDate!,
                  people: 0, // Partecipanti iniziali sempre 0
                  maxParticipants: int.parse(maxParticipantsController.text),
                  description: descriptionController.text,
                  zone: zoneController.text,
                  listType: selectedListType,
                  venue: selectedVenue,
                  participants: [],
                  pendingRequests: [],
                  ownerEmail: ownerEmail,
                );

                eventProvider.addEvent(newEvent);
                Navigator.pop(context);
              },
              child: const Text("Aggiungi Evento"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Text(selectedDate == null
                  ? "Seleziona data"
                  : "Data: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
            ),
          ],
        ),
      ),
    );
  }
}
