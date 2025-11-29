import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../providers/event_provider.dart';
import '../providers/venue_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/likes_provider.dart';
import '../utils/filter_preferences.dart';
import 'event_detail_page.dart';
import '../widgets/filter_zone.dart';
import '../widgets/filter_age.dart';

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
    final selectedAgeType = filters.ageFilterType ?? AgeRestrictionType.none;
    final selectedAgeValue = filters.ageFilterValue;
    final selectedDate = filters.dateFilter;

    return events.where((event) {
      if (selectedAgeType != AgeRestrictionType.none &&
          selectedAgeValue != null) {
        if (selectedAgeType == AgeRestrictionType.under) {
          if (event.ageRestrictionType == AgeRestrictionType.under) {
            if (event.ageRestrictionValue != null &&
                event.ageRestrictionValue! > selectedAgeValue) {
              return false;
            }
          } else if (event.ageRestrictionType == AgeRestrictionType.over) {
            return false;
          }
        } else if (selectedAgeType == AgeRestrictionType.over) {
          if (event.ageRestrictionType == AgeRestrictionType.over) {
            if (event.ageRestrictionValue != null &&
                event.ageRestrictionValue! < selectedAgeValue) {
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

      final name = event.name.toLowerCase();
      final desc = (event.description ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();
      if (searchQuery.isNotEmpty &&
          !name.contains(query) &&
          !desc.contains(query)) {
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

  @override
  Widget build(BuildContext context) {
    final events = Provider.of<EventProvider>(context).events;
    final venues = Provider.of<VenueProvider>(context).venues;
    final filters = Provider.of<FilterProvider>(context);
    final Map<String, Venue> venuesById = {for (var v in venues) v.id: v};
    final filteredEvents = applyFilters(events, filters);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search + filtro
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    FilterZone(
                      selectedZone: filters.selectedZone,
                      zones: getAllZones(events),
                      onZoneChanged: (zone) =>
                          filters.setSelectedZone(zone),
                    ),
                    const SizedBox(height: 10),
                    FilterAge(
                      selectedAgeType:
                          filters.ageFilterType ?? AgeRestrictionType.none,
                      ageValue: filters.ageFilterValue,
                      onAgeTypeChanged: (type) {
                        if (type != null) filters.setAgeFilterType(type);
                      },
                      onAgeValueChanged: (val) =>
                          filters.setAgeFilterValue(val),
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
                              initialDate:
                                  filters.dateFilter ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              filters.setDateFilter(picked);
                            }
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
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[700]),
                          child: const Text("Azzera tutto"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Sezione Eventi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Eventi',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 230,
              child: filteredEvents.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessun evento trovato.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        final e = filteredEvents[index];
                        final venue =
                            e.venueId != null ? venuesById[e.venueId!] : null;
                        return _EventCardHorizontal(
                          event: e,
                          venue: venue,
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // Sezione Strutture
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Strutture',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 230,
              child: venues.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessuna struttura aggiunta.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: venues.length,
                      itemBuilder: (context, index) {
                        final v = venues[index];
                        return _VenueCardHorizontal(venue: v);
                      },
                    ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// CARD ORIZZONTALE EVENTO
class _EventCardHorizontal extends StatelessWidget {
  final Event event;
  final Venue? venue;

  const _EventCardHorizontal({
    super.key,
    required this.event,
    this.venue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailPage(event: event),
            ),
          );
        },
        child: Card(
          color: const Color(0xFF1F1F2F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Immagine in alto (usa imagePath se la aggiungi al modello)
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/event_placeholder.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${event.date.day}/${event.date.month}/${event.date.year}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          if (venue != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              venue!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            "${event.participants.length} / ${event.maxParticipants} persone",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    _LikeIconSmall(eventId: event.id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CUORE PICCOLO NELLA CARD
class _LikeIconSmall extends StatelessWidget {
  final String eventId;

  const _LikeIconSmall({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final prefs = snap.data!;
        final email = prefs.getString('user_email') ?? '';
        if (email.isEmpty) return const SizedBox.shrink();

        final likesProvider = Provider.of<LikesProvider>(context);
        final isLiked = likesProvider.isLiked(email, eventId);

        return IconButton(
          icon: Icon(
            isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            color: isLiked ? Colors.redAccent : Colors.white70,
            size: 22,
          ),
          onPressed: () {
            Provider.of<LikesProvider>(context, listen: false)
                .toggleLike(email, eventId);
          },
        );
      },
    );
  }
}

// CARD ORIZZONTALE STRUTTURA
class _VenueCardHorizontal extends StatelessWidget {
  final Venue venue;

  const _VenueCardHorizontal({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
      child: Card(
        color: const Color(0xFF1F1F2F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Image.asset(
                'assets/images/venue_placeholder.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    venue.address ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (venue.capacity != null)
                    Text(
                      "Capienza: ${venue.capacity}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
