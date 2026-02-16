import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'events_page.dart';
import 'profile_page.dart';
import 'chat_list_page.dart';
import 'add_event.dart';
import 'add_venue.dart';
import 'event_detail_screen.dart';
import '../models/event.dart';
import '../models/venue.dart';
import '../providers/event_provider.dart';
import '../providers/venue_provider.dart';
import '../providers/likes_provider.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserEmail;

  const HomeScreen({super.key, required this.currentUserEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Questa è la lista che gestisce la navigazione tra le tue pagine
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Carica i like dell'utente corrente all'avvio
    Provider.of<LikesProvider>(context, listen: false)
        .loadForUser(widget.currentUserEmail);

    _pages = [
      const EventsPage(),           // 0 - Home
      const EventsPage(onlyFavorites: true), // 1 - MODIFICATO: Ora carica i Preferiti veri
      const SizedBox.shrink(),      // 2 - Spazio per il tasto centrale
      const MapScreen(),            // 3 - Map
      ProfilePage(                 // 4 - Profile
        currentUserEmail: widget.currentUserEmail,
        profileUserEmail: widget.currentUserEmail,
        profileUserName: '',
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 2) return; // Evitiamo che clicchi sul "buco" del tasto +
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatListPage(currentUserEmail: widget.currentUserEmail),
      ),
    );
  }

  // --- TUA LOGICA ORIGINALE INTEGRALE ---
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
          builder: (_) => AddVenueScreen(
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
      extendBody: true, // Fondamentale per far vedere il contenuto dietro la barra curva
      appBar: AppBar(
        title: const Text('GeoEvent', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_rounded, color: Colors.black),
            onPressed: _navigateToChat,
          ),
        ],
      ),
      // MODIFICA: Usiamo IndexedStack per non perdere lo stato delle pagine (e i filtri) quando navighi
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavButton(Icons.home_rounded, "Home", 0),
              _buildNavButton(Icons.favorite_rounded, "Likes", 1),
              const SizedBox(width: 40), // Spazio centrale per il FAB
              _buildNavButton(Icons.map_rounded, "Mappa", 3),
              _buildNavButton(Icons.person_rounded, "Profilo", 4),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: () => _openAddEventFromFab(context),
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.amber[800] : Colors.grey),
          Text(label, style: TextStyle(
            fontSize: 10, 
            color: isSelected ? Colors.amber[800] : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )),
        ],
      ),
    );
  }
}