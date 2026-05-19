import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../providers/event_provider.dart';
import '../providers/venue_provider.dart';
import '../providers/likes_provider.dart';
import 'event_detail_page.dart';
import 'venue_detail_screen.dart';
import 'all_events_page.dart';
import 'all_venues_page.dart';

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
  int _selectedTab = 0; // 0: Preferiti, 1: Partecipazioni
  int _favoriteType = 0; // 0: Eventi, 1: Strutture (Sottolivello)

  @override
  void initState() {
    super.initState();
    _loadUser();
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

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final venueProvider = Provider.of<VenueProvider>(context);
    final likes = Provider.of<LikesProvider>(context);

    // Lista per le Strutture suggerite (Home)
    final List<Venue> displayVenuesHome = venueProvider.venues.where((v) => 
      v.ownerEmail.trim().toLowerCase() != _currentEmail.trim().toLowerCase()
    ).toList();

    List<dynamic> displayList = [];
    List<Event> displayEventsHome = [];
    
    if (widget.onlyFavorites) {
      if (_selectedTab == 1) {
        // PARTECIPAZIONI
        displayList = eventProvider.getUpcomingParticipations(_currentEmail);
      } else {
        // PREFERITI -> Filtro pillola sottostante
        displayList = _favoriteType == 0
            ? eventProvider.events.where((e) => likes.isLiked(e.id)).toList()
            : venueProvider.venues.where((v) => likes.isVenueLiked(v.id)).toList();
      }
    } else {
      // LOGICA HOME NORMALE
      displayEventsHome = eventProvider.events.where((e) => 
        e.ownerEmail.trim().toLowerCase() != _currentEmail.trim().toLowerCase()
      ).toList();

      if (searchQuery.isNotEmpty) {
        displayEventsHome = displayEventsHome.where((e) =>
          e.name.toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.onlyFavorites) ...[
              _buildTabSelector(),
              if (_selectedTab == 0) _buildSubTabSelector(), // Appare solo in Preferiti
            ] else 
              _buildSearchBar(),
            
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
                        displayEventsHome.isEmpty
                          ? _buildEmptyState("Nessun evento disponibile")
                          : _buildHorizontalEventList(displayEventsHome),

                        const SizedBox(height: 10),

                        _buildHeader(
  "Strutture suggerite",
  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllVenuesPage(currentUserEmail: _currentEmail)))
),
                        _buildHorizontalVenueList(displayVenuesHome),
                      ] else ...[
                        const SizedBox(height: 10),
                        if (displayList.isEmpty)
                          _buildEmptyState("Nessun contenuto trovato")
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: displayList.length,
                            itemBuilder: (context, index) {
                              final item = displayList[index];
                              if (item is Event) return _EventCardVertical(event: item);
                              if (item is Venue) return _VenueCardVertical(venue: item);
                              return const SizedBox.shrink();
                            },
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

  // --- WIDGETS DI SELEZIONE ---

  Widget _buildSubTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.grey[100], 
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            _subTabButton("Eventi", 0),
            _subTabButton("Strutture", 1),
          ],
        ),
      ),
    );
  }

  Widget _subTabButton(String text, int index) {
    bool isSelected = _favoriteType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _favoriteType = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  // --- ALTRI WIDGETS (Header, Search, etc.) ---

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100], 
          borderRadius: BorderRadius.circular(15)
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12), 
              child: Icon(Icons.search, color: Colors.amber)
            ),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Cerca evento...", 
                  border: InputBorder.none
                ),
                onChanged: (val) => setState(() => searchQuery = val)
              )
            ),
            if (searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: () => setState(() => searchQuery = ''),
              ),
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
        onTap: () => setState(() {
          _selectedTab = index;
          if (index == 1) _favoriteType = 0; // Reset sottolivello se si va in partecipazioni
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent, 
            borderRadius: BorderRadius.circular(16)
          ),
          child: Text(
            text, 
            textAlign: TextAlign.center, 
            style: TextStyle(
              fontSize: 14, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
              color: isSelected ? Colors.black : Colors.grey[600]
            )
          ),
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
          TextButton(
            onPressed: onTap, 
            child: const Text("Esplora tutti", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600))
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
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: list.length > 5 ? 5 : list.length,
        itemBuilder: (context, index) => _VenueCardHorizontal(venue: list[index], userEmail: _currentEmail),
      ),
    );
  }
}

// --- CARD COMPONENTS ---

class _EventCardHorizontal extends StatelessWidget {
  final Event event;
  final String userEmail;
  const _EventCardHorizontal({required this.event, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final likesProvider = Provider.of<LikesProvider>(context);
    bool isLiked = likesProvider.isLiked(event.id);
    final months = ["GEN", "FEB", "MAR", "APR", "MAG", "GIU", "LUG", "AGO", "SET", "OTT", "NOV", "DIC"];
    String monthStr = months[event.date.month - 1];

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(event: event))),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Positioned.fill(child: (event.imagePaths.isNotEmpty && File(event.imagePaths.first).existsSync()) 
                        ? Image.file(File(event.imagePaths.first), fit: BoxFit.cover) 
                        : Container(color: Colors.amber[50], child: const Icon(Icons.image, color: Colors.amber))),
                      Positioned(
                        top: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(monthStr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo)),
                              Text("${event.date.day}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12, right: 12,
                        child: GestureDetector(
                          onTap: () => likesProvider.toggleLike(userEmail, event.id),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(event.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text("${event.date.hour}:${event.date.minute.toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text(event.zone ?? 'Milano', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VenueCardHorizontal extends StatelessWidget {
  final Venue venue;
  final String userEmail;
  const _VenueCardHorizontal({required this.venue, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final likesProvider = Provider.of<LikesProvider>(context);
    bool isLiked = likesProvider.isVenueLiked(venue.id);
    bool isOwner = venue.ownerEmail.trim().toLowerCase() == userEmail.trim().toLowerCase();

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: venue))),
        child: Card(
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            children: [
              Positioned.fill(child: (venue.imagePath != null && File(venue.imagePath!).existsSync()) 
                ? Image.file(File(venue.imagePath!), fit: BoxFit.cover) 
                : Container(color: Colors.amber[50], child: const Icon(Icons.store, color: Colors.amber))),
              Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])))),
              
              // CUORICINO PER STRUTTURA (solo se non proprietario)
              if (!isOwner)
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: () => likesProvider.toggleVenueLike(userEmail, venue.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey, size: 18),
                    ),
                  ),
                ),

              Positioned(
                bottom: 12, left: 12, right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(venue.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (venue.address != null)
                      Text(venue.address!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

class _EventCardVertical extends StatelessWidget {
  final Event event;
  const _EventCardVertical({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(event: event))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 55, height: 55,
          decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12)),
          child: (event.imagePaths.isNotEmpty && File(event.imagePaths.first).existsSync())
              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(event.imagePaths.first), fit: BoxFit.cover))
              : const Icon(Icons.celebration, color: Colors.amber),
        ),
        title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("${event.date.day}/${event.date.month} • ${event.zone ?? 'Milano'}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}

class _VenueCardVertical extends StatelessWidget {
  final Venue venue;
  const _VenueCardVertical({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: venue))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 55, height: 55,
          decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12)),
          child: (venue.imagePath != null && File(venue.imagePath!).existsSync())
              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(venue.imagePath!), fit: BoxFit.cover))
              : const Icon(Icons.store, color: Colors.amber),
        ),
        title: Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(venue.address ?? 'Indirizzo non disponibile', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}