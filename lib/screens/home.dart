import 'package:flutter/material.dart';

import 'events_page.dart';
import 'venues_page.dart';
import 'profile_page.dart';
import 'chat_list_page.dart';

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
  _pages = [
    const EventsPage(),
    const VenuesPage(),
    ProfilePage(
      currentUserEmail: widget.currentUserEmail,
      profileUserEmail: widget.currentUserEmail,
      profileUserName: 'Il tuo nome o username', // sostituisci con valore reale
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
        builder: (_) => ChatListPage(currentUserEmail: widget.currentUserEmail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoEvent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: _navigateToChat,
            tooltip: 'Chat',
          )
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Eventi'),
          BottomNavigationBarItem(icon: Icon(Icons.location_city), label: 'Strutture'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilo'),
        ],
      ),
    );
  }
}
