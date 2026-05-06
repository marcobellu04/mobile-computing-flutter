import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/venue_provider.dart';
import '../models/venue.dart';
import '../screens/venue_detail_screen.dart';
import '../widgets/filter_zone.dart';

class AllVenuesPage extends StatefulWidget {
  const AllVenuesPage({super.key});

  @override
  State<AllVenuesPage> createState() => _AllVenuesPageState();
}

class _AllVenuesPageState extends State<AllVenuesPage> {
  String? _selectedZone;

  // Helper per estrarre la zona dall'indirizzo (come discusso)
  String _getZoneFromAddress(String? address) {
    if (address == null || address.isEmpty) return 'Altro';
    if (address.contains(',')) {
      return address.split(',').last.trim();
    }
    return address;
  }

  // Logica di filtraggio speculare a quella degli eventi
  bool _applyFilters(Venue v) {
    return (_selectedZone == null || _selectedZone!.isEmpty) || 
           (_getZoneFromAddress(v.address) == _selectedZone);
  }

  @override
  Widget build(BuildContext context) {
    final venueProvider = context.watch<VenueProvider>();
    final allVenues = venueProvider.venues;

    // Generazione zone univoche
    final List<String> availableZones = allVenues
        .map((v) => _getZoneFromAddress(v.address))
        .where((z) => z.isNotEmpty)
        .toSet()
        .toList();

    final filteredVenues = allVenues.where((v) => _applyFilters(v)).toList();
    // Ordinamento alfabetico per nome (simile all'ordinamento per data degli eventi)
    filteredVenues.sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Esplora Strutture", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        // IconTheme per avere la freccia indietro nera come negli eventi
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // --- RIGA FILTRI (IDENTICA A ALL_EVENTS_PAGE) ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Filtro "Tutte" (Simulando i ChoiceChip temporali degli eventi)
                _buildAllFilterChip(),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(height: 20, child: VerticalDivider(color: Colors.grey)),
                ),

                // Filtro Zona (Tuo Widget FilterZone)
                FilterZone(
                  selectedZone: _selectedZone,
                  zones: availableZones,
                  onZoneChanged: (val) => setState(() => _selectedZone = val),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // --- LISTA RISULTATI ---
          Expanded(
            child: filteredVenues.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredVenues.length,
                    itemBuilder: (context, index) => _buildVenueCard(filteredVenues[index]),
                  ),
          ),
        ],
      ),
    );
  }

  // Chip per resettare velocemente (per mantenere la simmetria visiva con gli eventi)
  Widget _buildAllFilterChip() {
    final isSelected = _selectedZone == null;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: const Text("Tutte"),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedZone = null);
        },
        selectedColor: Colors.amber,
        backgroundColor: Colors.grey[100],
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 13, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.black : Colors.grey[700],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: isSelected ? Colors.amber : Colors.transparent),
      ),
    );
  }

  // Card clonata dalla funzione _buildEventCard
  Widget _buildVenueCard(Venue venue) {
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
          MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: venue))
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 55, 
          height: 55,
          decoration: BoxDecoration(
            color: Colors.amber[50], // Amber come gli eventi per coerenza totale
            borderRadius: BorderRadius.circular(12),
          ),
          child: (venue.imagePath != null && File(venue.imagePath!).existsSync())
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12), 
                  child: Image.file(File(venue.imagePath!), fit: BoxFit.cover),
                )
              : const Icon(Icons.store, color: Colors.amber),
        ),
        title: Text(
          venue.name, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  venue.address ?? 'Zona n.d.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }

  // Empty State clonato da AllEventsPage
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 70, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            "Nessuna struttura trovata",
            style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _selectedZone = null),
            child: const Text("Resetta filtri", style: TextStyle(color: Colors.amber)),
          )
        ],
      ),
    );
  }
}