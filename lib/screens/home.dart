import 'package:flutter/material.dart';

import 'events_page.dart';
import 'venues_page.dart';
import 'add_event.dart';   // <-- Importa la pagina per aggiungere eventi
import 'add_venue.dart';  // <-- Importa la nuova pagina per aggiungere strutture
import 'profile_page.dart'; // <-- Importa la pagina profilo account (da creare)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const EventsPage(),
    const VenuesPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Organizer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            tooltip: 'Profilo',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Eventi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city),
            label: 'Strutture',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedIndex == 0) {
            // Aggiungi Evento
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddEventScreen()),
            ).then((_) => setState(() {}));
          } else if (_selectedIndex == 1) {
            // Aggiungi Struttura
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddVenueScreen()),
            ).then((_) => setState(() {}));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
