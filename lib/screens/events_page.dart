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
import 'all_events_page.dart'; // ✅ DA CREARE
import 'all_venues_page.dart'; // ✅ DA CREARE
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
      setState(() {
        currentUser = User.fromMap(userMap);
      });
    }

    if (email != null && email.isNotEmpty) {
      setState(() {
        _currentEmail = email!;
      });
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
    final events = Provider.of<EventProvider>(context).events;
    final venues = Provider.of<VenueProvider>(context).venues;
    final filters = Provider.of<FilterProvider>(context);
    final likes = Provider.of<LikesProvider>(context);
    
    final filteredEvents = events.where((event) {
      if (widget.onlyFavorites && !likes.isLiked(event.id)) return false;
      if (searchQuery.isNotEmpty && !event.name.toLowerCase().contains(searchQuery.toLowerCase())) return false;
      if (filters.selectedZone != null && filters.selectedZone!.isNotEmpty && event.zone != filters.selectedZone) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BARRA RICERCA ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.search, color: Colors.amber)),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(hintText: "Cerca...", border: InputBorder.none),
                        onChanged: (val) => setState(() => searchQuery = val),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list_rounded), 
                      onPressed: () => setState(() => _showFilterMenu = !_showFilterMenu)
                    )
                  ],
                ),
              ),
            ),

            if (_showFilterMenu)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilterZone(
                  selectedZone: filters.selectedZone,
                  zones: getAllZones(events),
                  onZoneChanged: (z) => filters.setSelectedZone(z),
                ),
              ),

            // --- INTESTAZIONE EVENTI CON "MOSTRA TUTTO" ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.onlyFavorites ? 'I tuoi Preferiti' : 'Eventi in primo piano', 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  if (filteredEvents.length > 5)
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllEventsPage())),
                      child: const Text("Mostra tutto", style: TextStyle(color: Colors.amber)),
                    ),
                ],
              ),
            ),

            // --- LISTA ORIZZONTALE EVENTI (MAX 5) ---
            SizedBox(
              height: 250,
              child: filteredEvents.isEmpty
                ? Center(child: Text(widget.onlyFavorites ? 'Nessun preferito salvato' : 'Nessun evento trovato'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
                    // ✅ LIMITE DI 5 ELEMENTI
                    itemCount: filteredEvents.length > 5 ? 5 : filteredEvents.length,
                    itemBuilder: (context, index) {
                      return _EventCardHorizontal(
                        event: filteredEvents[index],
                        userEmail: _currentEmail,
                      );
                    },
                  ),
            ),

            // --- SEZIONE STRUTTURE (Solo se non siamo nei preferiti) ---
            if (!widget.onlyFavorites) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Strutture suggerite', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (venues.length > 5)
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllVenuesPage())),
                        child: const Text("Mostra tutto", style: TextStyle(color: Colors.amber)),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 180,
                child: venues.isEmpty
                  ? const Center(child: Text("Nessuna struttura disponibile"))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 16),
                      // ✅ LIMITE DI 5 ELEMENTI
                      itemCount: venues.length > 5 ? 5 : venues.length,
                      itemBuilder: (context, index) => _VenueCardHorizontal(venue: venues[index]),
                    ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ... Resto dei widget _EventCardHorizontal e _VenueCardHorizontal invariati ...

class _EventCardHorizontal extends StatelessWidget {
  final Event event;
  final String userEmail;
  const _EventCardHorizontal({required this.event, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final likesProvider = Provider.of<LikesProvider>(context);
    final bool isLiked = likesProvider.isLiked(event.id);

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
              // ✅ FIX: Caricamento immagine evento
              Positioned.fill(
                child: Hero(
                  tag: 'event-${event.id}',
                  child: (event.imagePath != null && File(event.imagePath!).existsSync())
                      ? Image.file(
                          File(event.imagePath!), 
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(color: Colors.amber[50], child: const Icon(Icons.broken_image, color: Colors.amber)),
                        )
                      : Container(
                          color: Colors.amber.withOpacity(0.1),
                          child: const Icon(Icons.image, color: Colors.amber, size: 50),
                        ),
                ),
              ),
              // Gradiente per leggere il testo
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      event.name, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    Text(
                      event.zone ?? '', 
                      style: const TextStyle(color: Colors.white70, fontSize: 12)
                    ),
                  ],
                ),
              ),
              // Tasto Like
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    if (userEmail.isNotEmpty) {
                      likesProvider.toggleLike(userEmail, event.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Effettua il login per salvare i preferiti"))
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
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
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        // ✅ AGGIUNTO GESTURE DETECTOR PER RENDERE CLICCABILE
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VenueDetailScreen(venue: venue),
            ),
          );
        },
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              Expanded(
                child: Hero(
                  tag: 'venue-${venue.id}', // ✅ AGGIUNTO HERO PER STRUTTURA
                  child: (venue.imagePath != null && File(venue.imagePath!).existsSync())
                      ? Image.file(
                          File(venue.imagePath!), 
                          width: double.infinity, 
                          fit: BoxFit.cover
                        )
                      : Container(
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.storefront, size: 40, color: Colors.amber),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  venue.name, 
                  style: const TextStyle(fontWeight: FontWeight.bold), 
                  textAlign: TextAlign.center, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}