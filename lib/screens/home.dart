import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'events_page.dart';
import 'profile_page.dart';
import 'chat_list_page.dart';
import 'add_event.dart';
import 'add_venue.dart';
import '../providers/likes_provider.dart';
import '../providers/message_provider.dart';
import 'map_screen.dart';

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

    Provider.of<LikesProvider>(context, listen: false)
        .loadForUser(widget.currentUserEmail);

    _pages = [
      const EventsPage(),
      const EventsPage(onlyFavorites: true),
      const SizedBox.shrink(),
      const MapScreen(),
      ProfilePage(
        currentUserEmail: widget.currentUserEmail,
        profileUserEmail: widget.currentUserEmail,
        profileUserName: '',
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 2) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatListPage(
          currentUserEmail: widget.currentUserEmail,
        ),
      ),
    );
  }

  Future<void> _openAddEventFromFab(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cosa vuoi aggiungere?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, 'event'),
                  icon: const Icon(
                    Icons.event,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'AGGIUNGI EVENTO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'venue'),
                  icon: const Icon(
                    Icons.business,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'AGGIUNGI STRUTTURA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (choice == null) return;

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';

    String ownerName = email.split('@')[0];
String ownerSurname = '';

    if (email.isNotEmpty) {
      final jsonString = prefs.getString('user_data_$email');

      if (jsonString != null) {
  final map = jsonDecode(jsonString) as Map<String, dynamic>;

  ownerName = (map['name'] ?? ownerName) as String;
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
    final messageProvider = context.watch<MessageProvider>();
    final summaries =
        messageProvider.getChatSummariesForUser(widget.currentUserEmail);

    int totalUnread = 0;
    for (final s in summaries) {
      totalUnread += messageProvider.getUnreadCount(
        widget.currentUserEmail,
        s.userEmail,
      );
    }

    return Scaffold(
      extendBody: true,

      body: Stack(
  children: [
    IndexedStack(
      index: _selectedIndex,
      children: _pages,
    ),

    // HEADER CUSTOM SOLO NELLA HOME
    if (_selectedIndex == 0)
      Positioned(
        top: MediaQuery.of(context).padding.top + 14,
        left: 18,
        right: 16,
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            // TITOLO BRAND
            const Text(
              'GEOEVENT',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF320064),
                letterSpacing: -1.2,
              ),
            ),

            // CHAT BUTTON
            Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.black,
                      size: 25,
                    ),
                    onPressed: _navigateToChat,
                  ),
                ),

                // BADGE NOTIFICHE
                if (totalUnread > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      constraints:
                          const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        totalUnread > 99
                            ? '99+'
                            : '$totalUnread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.bold,
                        ),
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
  ],
),

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: Colors.white,
        elevation: 20,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(
                Icons.explore_outlined,
                Icons.explore,
                "Home",
                0,
              ),
              _buildNavButton(
                Icons.favorite_outline_rounded,
                Icons.favorite_rounded,
                "Likes",
                1,
              ),
              const SizedBox(width: 40),
              _buildNavButton(
                Icons.map_outlined,
                Icons.map_rounded,
                "Mappa",
                3,
              ),
              _buildNavButton(
                Icons.person_outline_rounded,
                Icons.person_rounded,
                "Profilo",
                4,
              ),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        shape: const CircleBorder(),
        elevation: 6,
        onPressed: () => _openAddEventFromFab(context),
        child: const Icon(
          Icons.add,
          color: Colors.black,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildNavButton(
    IconData iconOff,
    IconData iconOn,
    String label,
    int index,
  ) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? iconOn : iconOff,
              color: isSelected ? Colors.amber[900] : Colors.grey[600],
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.amber[900] : Colors.grey[600],
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}