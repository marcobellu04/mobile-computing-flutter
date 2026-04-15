import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_first_app/widgets/filter_age.dart';
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
import 'venue_detail_screen.dart';
import 'all_events_page.dart';
import 'all_venues_page.dart';
import '../widgets/filter_zone.dart';

class EventsPage extends StatefulWidget {
  final bool onlyFavorites;
  const EventsPage({super.key, this.onlyFavorites = false});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  User? currentUser;
  String _currentEmail = '';
  String searchQuery = '';
  final FilterPreferences _filterPreferences = FilterPreferences();
  bool _showFilterMenu = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadFilters();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('user_email');
    final userDataString = prefs.getString('user_data');
    
    if (userDataString != null) {
      final Map<String, dynamic> userMap = jsonDecode(userDataString);
      email ??= userMap['email'];
      setState(() => currentUser = User.fromMap(userMap));
    }
    
    if (email != null && email.isNotEmpty) {
      setState(() => _currentEmail = email!);
      Provider.of<LikesProvider>(context, listen: false).loadForUser(email);
    }
  }

  void _saveCurrentFilters(FilterProvider filters) {
  _filterPreferences.saveFilters(
    filters.selectedZone,
    filters.ageFilterType?.index ?? 0,
    filters.ageFilterValue,
    filters.dateFilter,
  );
}
  Future<void> _loadFilters() async {
    final filtersMap = await _filterPreferences.loadFilters();
    if (mounted) {
      Provider.of<FilterProvider>(context, listen: false).loadFromMap(filtersMap);
    }
  }

  List<String> getAllZones(List<Event> events) {
  return events
      .map((e) => e.zone?.trim()) // Rimuove spazi bianchi accidentali
      .where((z) => z != null && z.isNotEmpty)
      .cast<String>()
      .toSet() // Rimuove i duplicati
      .toList()
    ..sort(); // Mette le zone in ordine alfabetico (molto più ordinato!)
}

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final venues = Provider.of<VenueProvider>(context).venues;
    final filters = Provider.of<FilterProvider>(context);
    final likes = Provider.of<LikesProvider>(context);

    List<Event> displayEvents = [];
    
    if (widget.onlyFavorites) {
      displayEvents = _selectedTab == 0
          ? eventProvider.events.where((e) => likes.isLiked(e.id)).toList()
          : eventProvider.getUpcomingParticipations(_currentEmail);
    } else {
      List<Event> allEvents = eventProvider.events;

      // Filtro ricerca locale
      if (searchQuery.isNotEmpty) {
        allEvents = allEvents.where((e) => 
          e.name.toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();
      }

      // Applicazione filtri globali (Logica nel Provider)
      displayEvents = filters.applyFilters(allEvents);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.onlyFavorites) _buildTabSelector() else _buildSearchBar(filters),
            
           // Dentro il build di EventsPage.dart
if (_showFilterMenu && !widget.onlyFavorites)
  Container(
    padding: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
    ),
    child: Column(
      children: [
        // 1. FILTRO ZONA
        FilterZone(
          selectedZone: filters.selectedZone,
          zones: getAllZones(eventProvider.events),
          onZoneChanged: (z) {
            filters.setSelectedZone(z);
            _saveCurrentFilters(filters); 
          },
        ),
        
        // 2. FILTRO ETÀ
        FilterAge(
          selectedAgeType: filters.ageFilterType ?? AgeRestrictionType.none,
          ageValue: filters.ageFilterValue,
          onAgeTypeChanged: (type) {
            if (type != null) {
              filters.setAgeFilterType(type); // Nome corretto
              _saveCurrentFilters(filters);
            }
          },
          onAgeValueChanged: (val) {
            filters.setAgeFilterValue(val); // Nome corretto
            _saveCurrentFilters(filters);
          },
        ),
      ],
    ),
  ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.onlyFavorites) ...[
                        _buildHeader(
                          "Eventi per te",
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllEventsPage()))
                        ),
                        displayEvents.isEmpty 
                          ? _buildEmptyState("Nessun evento trovato")
                          : _buildHorizontalEventList(displayEvents),

                        const SizedBox(height: 10),

                        _buildHeader(
                          "Strutture suggerite",
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllVenuesPage()))
                        ),
                        _buildHorizontalVenueList(venues),
                      ] else ...[
                        const SizedBox(height: 10),
                        if (displayEvents.isEmpty)
                          _buildEmptyState("Nessun contenuto trovato")
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: displayEvents.length,
                            itemBuilder: (context, index) => _EventCardVertical(event: displayEvents[index]),
                          ),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS UI ---

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
      ),
    );
  }

  Widget _buildSearchBar(FilterProvider filters) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.search, color: Colors.amber)),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(hintText: "Cerca evento...", border: InputBorder.none),
                onChanged: (val) => setState(() => searchQuery = val)
              )
            ),
            if (filters.selectedZone != null || filters.dateFilter != null)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.orange, size: 20),
                onPressed: () {
                  filters.clearAll();
                  _filterPreferences.saveFilters(null, 0, null, null);
                },
              ),
            IconButton(
              icon: Icon(Icons.filter_list_rounded, color: _showFilterMenu ? Colors.amber : Colors.black),
              onPressed: () => setState(() => _showFilterMenu = !_showFilterMenu)
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _tabButton("Preferiti", 0),
          _tabButton("Partecipazioni", 1),
        ],
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(16)),
          child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.black : Colors.grey[600])),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(onPressed: onTap, child: const Text("Mostra tutto", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildHorizontalEventList(List<Event> list) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: list.length > 5 ? 5 : list.length,
        itemBuilder: (context, index) => _EventCardHorizontal(event: list[index], userEmail: _currentEmail),
      ),
    );
  }

  Widget _buildHorizontalVenueList(List<Venue> list) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: list.length > 5 ? 5 : list.length,
        itemBuilder: (context, index) => _VenueCardHorizontal(venue: list[index]),
      ),
    );
  }
}

// --- CARD WIDGETS ---

class _EventCardHorizontal extends StatelessWidget {
  final Event event;
  final String userEmail;
  const _EventCardHorizontal({required this.event, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final likesProvider = Provider.of<LikesProvider>(context);
    bool isLiked = likesProvider.isLiked(event.id);
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(event: event))),
        child: Card(
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            children: [
              Positioned.fill(
                child: (event.imagePath != null && File(event.imagePath!).existsSync())
                  ? Image.file(File(event.imagePath!), fit: BoxFit.cover)
                  : Container(color: Colors.amber[50], child: const Icon(Icons.image, color: Colors.amber))
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)]
                    )
                  )
                )
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(event.zone ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                )
              ),
              Positioned(
                top: 5,
                left: 5,
                child: IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.white),
                  onPressed: () => likesProvider.toggleLike(userEmail, event.id)
                )
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.listType == ListType.open ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.listType == ListType.open ? 'APERTA' : 'CHIUSA',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCardVertical extends StatelessWidget {
  final Event event;
  const _EventCardVertical({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (event.imagePath != null && File(event.imagePath!).existsSync())
            ? Image.file(File(event.imagePath!), width: 50, height: 50, fit: BoxFit.cover)
            : const Icon(Icons.event, color: Colors.amber)
        ),
        title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${event.zone ?? ''} • ${event.date.day}/${event.date.month}"),
        trailing: Icon(
          event.listType == ListType.open ? Icons.lock_open : Icons.lock_outline,
          size: 18,
          color: event.listType == ListType.open ? Colors.green : Colors.red,
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(event: event))),
      ),
    );
  }
}

class _VenueCardHorizontal extends StatelessWidget {
  final Venue venue;
  const _VenueCardHorizontal({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: venue))),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: (venue.imagePath != null && File(venue.imagePath!).existsSync())
                  ? Image.file(File(venue.imagePath!), fit: BoxFit.cover, width: double.infinity)
                  : Container(color: Colors.grey[100], child: const Icon(Icons.store, color: Colors.amber))
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(venue.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))
            ),
          ]),
        ),
      ),
    );
  }
}