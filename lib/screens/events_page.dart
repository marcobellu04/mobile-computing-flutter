import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../providers/event_provider.dart';
import '../providers/venue_provider.dart';
import 'event_detail_page.dart';
import '../widgets/rounded_card.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  User? currentUser;
  String searchQuery = '';
  String? selectedZone;

  AgeRestrictionType ageFilterType = AgeRestrictionType.none;
  int? ageFilterValue;

  List<String> getAllZones(List<Event> events) {
    final zones = <String>{};
    for (final e in events) {
      final zone = e.zone;
      if (zone != null && zone.isNotEmpty) {
        zones.add(zone);
      }
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

  List<Event> applyFilters(List<Event> events) {
    final userAge = currentUser?.age;

    return events.where((event) {
      if (userAge != null &&
          event.ageRestrictionType != AgeRestrictionType.none &&
          event.ageRestrictionValue != null) {
        final ageRestriction = event.ageRestrictionValue!;
        switch (ageFilterType) {
          case AgeRestrictionType.under:
            if (ageFilterValue != null) {
              if (userAge >= ageFilterValue!) return false;
              if (event.ageRestrictionType == AgeRestrictionType.under &&
                  ageRestriction < userAge) return false;
            } else if (userAge > ageRestriction) {
              return false;
            }
            break;

          case AgeRestrictionType.over:
            if (ageFilterValue != null) {
              if (userAge <= ageFilterValue!) return false;
              if (event.ageRestrictionType == AgeRestrictionType.over &&
                  ageRestriction > userAge) return false;
            } else if (userAge < ageRestriction) {
              return false;
            }
            break;

          case AgeRestrictionType.none:
            // Se c’è restrizione evento e età utente supera i limiti escludi
            if (event.ageRestrictionType == AgeRestrictionType.under &&
                userAge > ageRestriction) return false;
            if (event.ageRestrictionType == AgeRestrictionType.over &&
                userAge < ageRestriction) return false;
            break;
        }
      }

      final name = event.name?.toLowerCase() ?? '';
      final description = event.description?.toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();
      if (searchQuery.isNotEmpty && !name.contains(query) && !description.contains(query)) {
        return false;
      }
      if (selectedZone != null && selectedZone!.isNotEmpty && event.zone != selectedZone) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildFilterSection(List<Event> events) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Cerca evento...",
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white54),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
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
              ...getAllZones(events).map(
                (z) => DropdownMenuItem(value: z, child: Text(z)),
              )
            ],
            onChanged: (value) {
              setState(() {
                selectedZone = value == '' ? null : value;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<AgeRestrictionType>(
                  value: ageFilterType,
                  decoration: const InputDecoration(labelText: 'Filtro età'),
                  items: AgeRestrictionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type == AgeRestrictionType.none
                          ? 'Nessun filtro'
                          : type == AgeRestrictionType.under
                              ? 'Under'
                              : 'Over'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        ageFilterType = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Età'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final number = int.tryParse(val);
                    setState(() {
                      ageFilterValue = number;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = Provider.of<EventProvider>(context).events;
    final venues = Provider.of<VenueProvider>(context).venues;
    final Map<String, Venue> venuesById = {for (var v in venues) v.id: v};
    final filteredEvents = applyFilters(events);

    return Column(
      children: [
        _buildFilterSection(events),
        Expanded(
          child: ListView.builder(
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              final e = filteredEvents[index];
              final venue = e.venueId != null ? venuesById[e.venueId!] : null;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: RoundedCard(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EventDetailPage(event: e)),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${e.participants.length} / ${e.maxParticipants} persone • "
                            "${e.date.day}/${e.date.month}/${e.date.year}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (venue != null)
                            Text(
                              "Struttura: ${venue.name}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          if (e.ageRestrictionValue != null)
                            Text(
                              "${e.ageRestrictionType == AgeRestrictionType.over ? 'Età min' : 'Età max'}: ${e.ageRestrictionValue}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
