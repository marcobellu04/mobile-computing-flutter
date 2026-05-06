import 'package:flutter/material.dart';

class FilterZone extends StatelessWidget {
  final String? selectedZone;
  final List<String> zones;
  final ValueChanged<String?> onZoneChanged;

  const FilterZone({
    super.key,
    required this.selectedZone,
    required this.zones,
    required this.onZoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        Icons.location_on, 
        size: 16, 
        color: selectedZone != null ? Colors.black : Colors.grey
      ),
      label: Text(selectedZone ?? "Tutte le zone"),
      onPressed: () => _showSearchModal(context),
      backgroundColor: selectedZone != null ? Colors.amber[100] : Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: selectedZone != null ? Colors.amber : Colors.transparent),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Fondamentale per far salire il modal con la tastiera
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25))
      ),
      builder: (context) {
        return _ZoneSearchSheet(
          zones: zones,
          initialZone: selectedZone,
          onZoneSelected: onZoneChanged,
        );
      },
    );
  }
}

// Widget interno per gestire lo stato della ricerca
class _ZoneSearchSheet extends StatefulWidget {
  final List<String> zones;
  final String? initialZone;
  final ValueChanged<String?> onZoneSelected;

  const _ZoneSearchSheet({
    required this.zones,
    this.initialZone,
    required this.onZoneSelected,
  });

  @override
  State<_ZoneSearchSheet> createState() => _ZoneSearchSheetState();
}

class _ZoneSearchSheetState extends State<_ZoneSearchSheet> {
  late List<String> filteredZones;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    filteredZones = widget.zones;
  }

  void _filterZones(String query) {
    setState(() {
      searchQuery = query;
      filteredZones = widget.zones
          .where((zone) => zone.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      // Adatta l'altezza in base alla tastiera
      height: MediaQuery.of(context).size.height * 0.7, 
      child: Column(
        children: [
          // Barretta grigia estetica in alto
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10)
            ),
          ),
          // Campo di Ricerca
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Cerca zona...",
              prefixIcon: const Icon(Icons.search, color: Colors.amber),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: _filterZones,
          ),
          const SizedBox(height: 10),
          // Lista Risultati
          Expanded(
            child: ListView(
              children: [
                if (searchQuery.isEmpty)
                  ListTile(
                    leading: const Icon(Icons.public, color: Colors.grey),
                    title: const Text("Tutte le zone", style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      widget.onZoneSelected(null);
                      Navigator.pop(context);
                    },
                  ),
                ...filteredZones.map((zone) => ListTile(
                  leading: const Icon(Icons.location_city, size: 20, color: Colors.grey),
                  title: Text(zone),
                  trailing: widget.initialZone == zone 
                      ? const Icon(Icons.check_circle, color: Colors.amber) 
                      : null,
                  onTap: () {
                    widget.onZoneSelected(zone);
                    Navigator.pop(context);
                  },
                )),
                if (filteredZones.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text("Nessuna zona trovata", 
                        style: TextStyle(color: Colors.grey[400])),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}