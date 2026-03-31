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
import 'event_detail_screen.dart';
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

  Future<void> _loadFilters() async {
    final filters = await _filterPreferences.loadFilters();
    Provider.of<FilterProvider>(context, listen: false).loadFromMap(filters);
  }

  List<String> getAllZones(List<Event> events) {
    return events.map((e) => e.zone).where((z) => z != null && z!.isNotEmpty).cast<String>().toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final events = eventProvider.events;
    final venues = Provider.of<VenueProvider>(context).venues;
    final filters = Provider.of<FilterProvider>(context);
    final likes = Provider.of<LikesProvider>(context);

    List<Event> displayEvents = [];
    if (widget.onlyFavorites) {
      displayEvents = _selectedTab == 0 
          ? events.where((e) => likes.isLiked(e.id)).toList()
          : eventProvider.getUpcomingParticipations(_currentEmail);
    } else {
      displayEvents = events.where((event) {
        if (searchQuery.isNotEmpty && !event.name.toLowerCase().contains(searchQuery.toLowerCase())) return false;
        if (filters.selectedZone != null && filters.selectedZone!.isNotEmpty && event.zone != filters.selectedZone) return false;
        return true;
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.onlyFavorites) _buildTabSelector() else _buildSearchBar(filters, events),
            
            if (_showFilterMenu && !widget.onlyFavorites)
              FilterZone(
                selectedZone: filters.selectedZone,
                zones: getAllZones(events),
                onZoneChanged: (z) => filters.setSelectedZone(z),
              ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.onlyFavorites) ...[
                      // --- SEZIONE EVENTI ---
                      _buildHeader(
                        "Eventi in primo piano", 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllEventsPage()))
                      ),
                      _buildHorizontalEventList(displayEvents),

                      const SizedBox(height: 10),

                      // --- SEZIONE STRUTTURE ---
                      _buildHeader(
                        "Strutture suggerite", 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllVenuesPage()))
                      ),
                      _buildHorizontalVenueList(venues),
                    ] else ...[
                      // --- SEZIONE PREFERITI ---
                      const SizedBox(height: 10),
                      if (displayEvents.isEmpty)
                        Center(child: Padding(padding: const EdgeInsets.all(50), child: Text("Nessun contenuto trovato", style: TextStyle(color: Colors.grey[400]))))
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
          ],
        ),
      ),
    );
  }

  // --- COMPONENTI UI ---

  Widget _buildSearchBar(FilterProvider filters, List<Event> events) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.search, color: Colors.amber)),
            Expanded(child: TextField(decoration: const InputDecoration(hintText: "Cerca...", border: InputBorder.none), onChanged: (val) => setState(() => searchQuery = val))),
            IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () => setState(() => _showFilterMenu = !_showFilterMenu))
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
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0), // Ridotto padding per allineare meglio
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: onTap, 
            child: const Text("Mostra tutto", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600))
          ),
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
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
        child: Card(
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            children: [
              Positioned.fill(child: (event.imagePath != null && File(event.imagePath!).existsSync()) ? Image.file(File(event.imagePath!), fit: BoxFit.cover) : Container(color: Colors.amber[50])),
              Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])))),
              Positioned(bottom: 12, left: 12, child: Text(event.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Positioned(top: 5, left: 5, child: IconButton(icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.white), onPressed: () => likesProvider.toggleLike(userEmail, event.id))),
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
        leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: (event.imagePath != null && File(event.imagePath!).existsSync()) ? Image.file(File(event.imagePath!), width: 50, height: 50, fit: BoxFit.cover) : const Icon(Icons.event)),
        title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(event.zone ?? ''),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(children: [
            Expanded(child: (venue.imagePath != null && File(venue.imagePath!).existsSync()) ? Image.file(File(venue.imagePath!), fit: BoxFit.cover, width: double.infinity) : const Icon(Icons.store, color: Colors.amber)),
            Padding(padding: const EdgeInsets.all(8.0), child: Text(venue.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
          ]),
        ),
      ),
    );
  }
}