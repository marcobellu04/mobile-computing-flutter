import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'events_page.dart';
import 'profile_page.dart';
import 'chat_list_page.dart';
import 'add_event.dart';
import 'add_venue.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../providers/event_provider.dart';
import '../providers/venue_provider.dart';
import 'event_detail_page.dart';
import '../providers/likes_provider.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserEmail;

  const HomeScreen({super.key, required this.currentUserEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // carica i like dell'utente corrente
    Provider.of<LikesProvider>(context, listen: false)
        .loadForUser(widget.currentUserEmail);

    _pages = [
      const EventsPage(),          // 0 - Home
      const _LikesPage(),          // 1 - Likes
      const _AddEventTab(),        // 2 - Add (centrale, ma il + vero è il FAB)
      const _MapPlaceholderPage(), // 3 - Map
      ProfilePage(                 // 4 - Profile
        currentUserEmail: widget.currentUserEmail,
        profileUserEmail: widget.currentUserEmail,
        profileUserName: '',
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChatListPage(currentUserEmail: widget.currentUserEmail),
      ),
    );
  }

  Future<void> _openAddEventFromFab(BuildContext context) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (context) {
      return SimpleDialog(
        title: const Text('Cosa vuoi aggiungere?'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'event'),
            child: const Text('Aggiungi evento'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'venue'),
            child: const Text('Aggiungi struttura'),
          ),
        ],
      );
    },
  );

  if (choice == null) return;

  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString('user_email') ?? '';

  String ownerName = '';
  String ownerSurname = '';

  if (email.isNotEmpty) {
    final jsonString = prefs.getString('user_data_$email');
    if (jsonString != null) {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      ownerName = (map['name'] ?? '') as String;
      ownerSurname = (map['surname'] ?? '') as String;
    }
  }

  if (email.isEmpty) return;

  if (choice == 'event') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEventScreen(
          ownerEmail: email,
          ownerName: ownerName,
          ownerSurname: ownerSurname,
        ),
      ),
    );
  } else if (choice == 'venue') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddVenueScreen(       // tua nuova pagina
          ownerEmail: email,
          ownerName: ownerName,
          ownerSurname: ownerSurname,
        ),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoEvent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_rounded),
            onPressed: _navigateToChat,
            tooltip: 'Chat',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.black45,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Likes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              activeIcon: Icon(Icons.add_box),
              label: 'Add',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        elevation: 4,
        onPressed: () => _openAddEventFromFab(context),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

// Tab centrale: lista rapida eventi (opzionale)
class _AddEventTab extends StatelessWidget {
  const _AddEventTab({super.key});

  @override
  Widget build(BuildContext context) {
    final events = Provider.of<EventProvider>(context).events;
    final venues = Provider.of<VenueProvider>(context).venues;
    final Map<String, Venue> venuesById = {for (var v in venues) v.id: v};

    if (events.isEmpty) {
      return const Center(
        child: Text('Crea un nuovo evento con il pulsante +'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final e = events[index];
        final venue = e.venueId != null ? venuesById[e.venueId!] : null;
        return ListTile(
          title: Text(e.name),
          subtitle: Text(
            "${e.date.day}/${e.date.month}/${e.date.year}"
            "${venue != null ? ' • ${venue.name}' : ''}",
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailPage(event: e),
              ),
            );
          },
        );
      },
    );
  }
}

// Likes REALI
class _LikesPage extends StatelessWidget {
  const _LikesPage({super.key});

  Future<String> _getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final events = Provider.of<EventProvider>(context).events;
    final venues = Provider.of<VenueProvider>(context).venues;
    final Map<String, Venue> venuesById = {for (var v in venues) v.id: v};
    final likesProvider = Provider.of<LikesProvider>(context);

    return FutureBuilder<String>(
      future: _getEmail(),
      builder: (context, snap) {
        final email = snap.data ?? '';
        if (email.isEmpty) {
          return const Center(
            child: Text('Effettua il login per vedere i tuoi preferiti'),
          );
        }

        final likedIds = likesProvider.likesFor(email);
        final likedEvents =
            events.where((e) => likedIds.contains(e.id)).toList();

        if (likedEvents.isEmpty) {
          return const Center(
            child: Text('Ancora nessun evento tra i preferiti'),
          );
        }

        return ListView.builder(
          itemCount: likedEvents.length,
          itemBuilder: (context, index) {
            final e = likedEvents[index];
            final venue =
                e.venueId != null ? venuesById[e.venueId!] : null;
            return ListTile(
              title: Text(e.name),
              subtitle: Text(
                "${e.date.day}/${e.date.month}/${e.date.year}"
                "${venue != null ? ' • ${venue.name}' : ''}",
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetailPage(event: e),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// Placeholder Map
class _MapPlaceholderPage extends StatelessWidget {
  const _MapPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Mappa eventi (in arrivo)'),
    );
  }
}
