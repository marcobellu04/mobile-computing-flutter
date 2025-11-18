import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import 'event_detail_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  User? currentUser;
  String searchQuery = '';
  String? selectedZone;

  List<String> getAllZones(List<Event> events) {
    final zones = <String>{};
    for (final e in events) {
      if (e.zone.isNotEmpty) zones.add(e.zone);
    }
    return zones.toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final Map<String, dynamic> userMap = jsonDecode(userDataString);
      setState(() {
        currentUser = User.fromMap(userMap);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = Provider.of<EventProvider>(context).events;

    final filteredEvents = events.where((event) {
      if (currentUser != null && event.ageRestriction != null) {
        if (currentUser!.age > event.ageRestriction!) return false;
      }

      if (searchQuery.isNotEmpty &&
          !event.name.toLowerCase().contains(searchQuery.toLowerCase()) &&
          !event.description.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }

      if (selectedZone != null && selectedZone!.isNotEmpty && event.zone != selectedZone) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: "Cerca evento...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: DropdownButtonFormField<String>(
            value: selectedZone,
            hint: const Text('Seleziona zona'),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: '', child: Text('Tutte le zone')),
              ...getAllZones(events)
                  .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                  .toList()
            ],
            onChanged: (value) {
              setState(() {
                selectedZone = value == '' ? null : value;
              });
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              final e = filteredEvents[index];
              return ListTile(
                title: Text(e.name),
                subtitle: Text(
                  "${e.people} persone • ${e.date.day}/${e.date.month}/${e.date.year}\n"
                  "Struttura: ${e.venue?.name ?? 'Nessuna'}"
                  "${e.ageRestriction != null ? "\nEtà max: ${e.ageRestriction}" : ""}",
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EventDetailPage(event: e)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
