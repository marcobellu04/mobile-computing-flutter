import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/event_provider.dart';
import '../screens/event_detail_page.dart';
import '../models/event.dart';
import '../widgets/filter_age.dart'; 
import '../widgets/filter_zone.dart';

enum TimeFilter { oggi, questaSettimana, tutti }

class AllEventsPage extends StatefulWidget {
  const AllEventsPage({super.key});

  @override
  State<AllEventsPage> createState() => _AllEventsPageState();
}

class _AllEventsPageState extends State<AllEventsPage> {
  // Stati per i filtri
  TimeFilter _selectedTimeFilter = TimeFilter.questaSettimana;
  String? _selectedZone;
  AgeRestrictionType _ageType = AgeRestrictionType.none;
  int? _ageValue;
  
  String _currentUserEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('user_email') ?? '';
    });
  }

  // --- LOGICA DI FILTRAGGIO AVANZATA ---
  bool _applyFilters(Event e) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(e.date.year, e.date.month, e.date.day);

    // 1. Filtro Temporale
    bool passesTime = true;
    if (_selectedTimeFilter == TimeFilter.oggi) {
      passesTime = eventDay.isAtSameMomentAs(today);
    } else if (_selectedTimeFilter == TimeFilter.questaSettimana) {
      final endOfWeek = today.add(Duration(days: 7 - today.weekday));
      passesTime = eventDay.isAfter(today.subtract(const Duration(seconds: 1))) && 
                   eventDay.isBefore(endOfWeek.add(const Duration(days: 1)));
    }

    // 2. Filtro Zona
    bool passesZone = (_selectedZone == null || _selectedZone!.isEmpty) || (e.zone == _selectedZone);

    // 3. Filtro Età
    bool passesAge = true;
    if (_ageType != AgeRestrictionType.none && _ageValue != null) {
      if (_ageType == AgeRestrictionType.under) {
        passesAge = (e.ageRestrictionType == AgeRestrictionType.under && e.ageRestrictionValue! <= _ageValue!);
      } else if (_ageType == AgeRestrictionType.over) {
        passesAge = (e.ageRestrictionType == AgeRestrictionType.over && e.ageRestrictionValue! >= _ageValue!);
      }
    }

    return passesTime && passesZone && passesAge;
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final allEvents = eventProvider.events;
    
    // Otteniamo la lista univoca delle zone esistenti dagli eventi
    final List<String> availableZones = allEvents
        .map((e) => e.zone ?? '')
        .where((z) => z.isNotEmpty)
        .toSet()
        .toList();

    final filteredEvents = allEvents.where((e) {
      final isNotMine = e.ownerEmail.trim().toLowerCase() != _currentUserEmail.trim().toLowerCase();
      return isNotMine && _applyFilters(e);
    }).toList();

    filteredEvents.sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Esplora Eventi", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // --- RIGA UNICA DI TUTTI I FILTRI (PILLOLE SCORREVOLI) ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Filtri Temporali
                _buildFilterChip("Oggi", TimeFilter.oggi),
                _buildFilterChip("Settimana", TimeFilter.questaSettimana),
                _buildFilterChip("Tutti", TimeFilter.tutti),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(height: 20, child: VerticalDivider(color: Colors.grey)),
                ),

                // Filtro Zona (Widget a Pillola)
                FilterZone(
                  selectedZone: _selectedZone,
                  zones: availableZones,
                  onZoneChanged: (val) => setState(() => _selectedZone = val),
                ),
                
                const SizedBox(width: 8),

                // Filtro Età (Widget a Pillola)
                FilterAge(
                  selectedAgeType: _ageType,
                  ageValue: _ageValue,
                  onAgeTypeChanged: (type) => setState(() => _ageType = type ?? AgeRestrictionType.none),
                  onAgeValueChanged: (val) => setState(() => _ageValue = val),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // --- LISTA RISULTATI ---
          Expanded(
            child: filteredEvents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) => _buildEventCard(filteredEvents[index]),
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET MINORI ---

  Widget _buildFilterChip(String label, TimeFilter filter) {
    final isSelected = _selectedTimeFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 13, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.black : Colors.grey[700],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedTimeFilter = filter);
        },
        selectedColor: Colors.amber,
        backgroundColor: Colors.grey[100],
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: isSelected ? Colors.amber : Colors.transparent),
      ),
    );
  }

 Widget _buildEventCard(Event event) {
    // Estraiamo la prima immagine valida dalla lista se presente
    String? firstImagePath;
    if (event.imagePaths != null && event.imagePaths!.isNotEmpty) {
      firstImagePath = event.imagePaths!.first;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(event: event))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 55, 
          height: 55,
          decoration: BoxDecoration(
            color: Colors.amber[50], 
            borderRadius: BorderRadius.circular(12),
          ),
          // Utilizzo di imagePaths.first per l'anteprima
          child: (firstImagePath != null && File(firstImagePath).existsSync())
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12), 
                  child: Image.file(File(firstImagePath), fit: BoxFit.cover),
                )
              : const Icon(Icons.celebration, color: Colors.amber),
        ),
        title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 70, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            "Nessun evento trovato",
            style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {
              _selectedTimeFilter = TimeFilter.tutti;
              _selectedZone = null;
              _ageType = AgeRestrictionType.none;
            }),
            child: const Text("Resetta filtri", style: TextStyle(color: Colors.amber)),
          )
        ],
      ),
    );
  }
}