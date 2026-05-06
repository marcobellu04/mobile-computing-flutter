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
  int _selectedTab = 0;

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
    final venues = Provider.of<VenueProvider>(context).venues;
    final likes = Provider.of<LikesProvider>(context);

    List<Event> displayEvents = [];
    
    if (widget.onlyFavorites) {
      displayEvents = _selectedTab == 0
          ? eventProvider.events.where((e) => likes.isLiked(e.id)).toList()
          : eventProvider.getUpcomingParticipations(_currentEmail);
    } else {
      displayEvents = eventProvider.events.where((e) => 
        e.ownerEmail.trim().toLowerCase() != _currentEmail.trim().toLowerCase()
      ).toList();

      if (searchQuery.isNotEmpty) {
        displayEvents = displayEvents.where((e) =>
          e.name.toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.onlyFavorites) _buildTabSelector() else _buildSearchBar(),
            
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
                          ? _buildEmptyState("Nessun evento disponibile")
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
                onPressed: () {
                  setState(() {
                    searchQuery = '';
                  });
                },
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
        onTap: () => setState(() => _selectedTab = index),
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
      height: 250, // Uguale agli eventi
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: list.length > 5 ? 5 : list.length,
        itemBuilder: (context, index) => _VenueCardHorizontal(venue: list[index]),
      ),
    );
  }
}

class _EventCardHorizontal extends StatelessWidget {
  final Event event;
  final String userEmail;
  const _EventCardHorizontal({required this.event, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final likesProvider = Provider.of<LikesProvider>(context);
    bool isLiked = likesProvider.isLiked(event.id);
    
    Widget eventImage;
    if (event.imagePaths.isNotEmpty && File(event.imagePaths.first).existsSync()) {
      eventImage = Image.file(File(event.imagePaths.first), fit: BoxFit.cover);
    } else {
      eventImage = Container(color: Colors.amber[50], child: const Icon(Icons.image, color: Colors.amber));
    }

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
              Positioned.fill(child: eventImage),
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
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
    String? firstImagePath;
    if (event.imagePaths.isNotEmpty) {
      firstImagePath = event.imagePaths.first;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: (firstImagePath != null && File(firstImagePath).existsSync())
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(firstImagePath), fit: BoxFit.cover),
                )
              : const Icon(Icons.celebration, color: Colors.amber),
        ),
        title: Text(
          event.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text("${event.date.day}/${event.date.month}"),
              const SizedBox(width: 12),
              const Icon(Icons.location_on, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(event.zone ?? 'Zona n.d.'),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}

class _VenueCardHorizontal extends StatelessWidget {
  final Venue venue;
  const _VenueCardHorizontal({required this.venue});

  @override
  Widget build(BuildContext context) {
    Widget venueImage;
    if (venue.imagePath != null && File(venue.imagePath!).existsSync()) {
      venueImage = Image.file(File(venue.imagePath!), fit: BoxFit.cover);
    } else {
      venueImage = Container(
        color: Colors.amber[50], 
        child: const Icon(Icons.store, color: Colors.amber)
      );
    }

    return Container(
      width: 240, // Larghezza uguale agli eventi
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: venue))
        ),
        child: Card(
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            children: [
              Positioned.fill(child: venueImage),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent, 
                        Colors.black.withOpacity(0.7)
                      ]
                    )
                  )
                )
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      venue.name, 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 16
                      )
                    ),
                    if (venue.address != null)
                      Text(
                        venue.address!, 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70, 
                          fontSize: 12
                        )
                      ),
                  ],
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}