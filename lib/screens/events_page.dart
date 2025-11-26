import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../providers/event_provider.dart';
import '../providers/venue_provider.dart';
import '../providers/filter_provider.dart';
import '../utils/filter_preferences.dart';
import 'event_detail_page.dart';
import '../widgets/rounded_card.dart';
import '../widgets/filter_zone.dart';
import '../widgets/filter_age.dart';
import 'chat_page.dart';
import 'add_event.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  User? currentUser;
  String searchQuery = '';
  final FilterPreferences _filterPreferences = FilterPreferences();
  bool _showFilterMenu = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadFilters();
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

  Future<void> _loadFilters() async {
    final filters = await _filterPreferences.loadFilters();
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);
    filterProvider.loadFromMap(filters);
  }

  Future<void> _saveFilters(FilterProvider filters) async {
    await _filterPreferences.saveFilters(
      filters.selectedZone,
      filters.ageFilterType?.index ?? 0,
      filters.ageFilterValue,
      filters.dateFilter,
    );
  }

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

  List<Event> applyFilters(List<Event> events, FilterProvider filters) {
    final userAge = currentUser?.age;
    final selectedAgeType = filters.ageFilterType ?? AgeRestrictionType.none;
    final selectedAgeValue = filters.ageFilterValue;
    final selectedDate = filters.dateFilter;

    return events.where((event) {
      if (selectedAgeType != AgeRestrictionType.none && selectedAgeValue != null) {
        if (selectedAgeType == AgeRestrictionType.under) {
          if (event.ageRestrictionType == AgeRestrictionType.under) {
            if (event.ageRestrictionValue != null && event.ageRestrictionValue! > selectedAgeValue) {
              return false;
            }
          } else if (event.ageRestrictionType == AgeRestrictionType.over) {
            return false;
          }
        } else if (selectedAgeType == AgeRestrictionType.over) {
          if (event.ageRestrictionType == AgeRestrictionType.over) {
            if (event.ageRestrictionValue != null && event.ageRestrictionValue! < selectedAgeValue) {
              return false;
            }
          } else if (event.ageRestrictionType == AgeRestrictionType.under) {
            return false;
          }
        }
      }
      if (filters.selectedZone != null &&
          filters.selectedZone!.isNotEmpty &&
          event.zone != filters.selectedZone) {
        return false;
      }
      if (selectedDate != null) {
        final eventDate = event.date;
        if (!(eventDate.year == selectedDate.year &&
            eventDate.month == selectedDate.month &&
            eventDate.day == selectedDate.day)) {
          return false;
        }
      }
      final name = event.name?.toLowerCase() ?? '';
      final desc = event.description?.toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();
      if (searchQuery.isNotEmpty && !name.contains(query) && !desc.contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _toggleFilterMenu() {
    setState(() {
      _showFilterMenu = !_showFilterMenu;
    });
  }

  Widget eventCreatorChatButton(Event event) {
    if (currentUser == null) return const SizedBox.shrink();

    if (currentUser!.email == event.ownerEmail) return const SizedBox.shrink();

    final creatorDisplayName = event.ownerEmail.split('@').first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(creatorDisplayName, style: const TextStyle(color: Colors.white70)),
        IconButton(
          icon: const Icon(Icons.message, color: Colors.white),
          tooltip: 'Chatta con il creatore evento',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  userEmail: currentUser!.email,
                  venueEmail: event.ownerEmail,
                  venueName: creatorDisplayName,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = Provider.of<EventProvider>(context).events;
    final venues = Provider.of<VenueProvider>(context).venues;
    final filters = Provider.of<FilterProvider>(context);
    final Map<String, Venue> venuesById = {for (var v in venues) v.id: v};
    final filteredEvents = applyFilters(events, filters);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Cerca evento...",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val;
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _toggleFilterMenu,
                )
              ],
            ),
          ),
          if (_showFilterMenu)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  FilterZone(
                    selectedZone: filters.selectedZone,
                    zones: getAllZones(events),
                    onZoneChanged: (zone) => filters.setSelectedZone(zone),
                  ),
                  const SizedBox(height: 10),
                  FilterAge(
                    selectedAgeType: filters.ageFilterType ?? AgeRestrictionType.none,
                    ageValue: filters.ageFilterValue,
                    onAgeTypeChanged: (type) {
                      if (type != null) filters.setAgeFilterType(type);
                    },
                    onAgeValueChanged: (val) => filters.setAgeFilterValue(val),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          filters.dateFilter != null
                              ? 'Data selezionata: ${filters.dateFilter!.toLocal().toString().split(' ')[0]}'
                              : 'Seleziona data',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.date_range),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: filters.dateFilter ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) filters.setDateFilter(picked);
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _saveFilters(filters);
                          _toggleFilterMenu();
                        },
                        child: const Text("Applica filtro"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          filters.clearAll();
                          _saveFilters(filters);
                          setState(() {
                            searchQuery = '';
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
                        child: const Text("Azzera tutto"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: filteredEvents.isEmpty
                ? const Center(
                    child: Text(
                      'Nessun evento trovato con i filtri selezionati.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
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
                                  const SizedBox(height: 10),
                                  eventCreatorChatButton(e),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final currentUserEmail = prefs.getString('user_email') ?? '';
          if (currentUserEmail.isEmpty) {
            // eventualmente mostra messaggio errore accesso
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEventScreen(ownerEmail: currentUserEmail),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Crea nuovo evento',
      ),
    );
  }
}
