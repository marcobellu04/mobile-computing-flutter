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
    return Padding(
      // Aggiungiamo un po' di respiro ai lati per non farlo toccare i bordi dello schermo
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selectedZone,
        // Riduce l'altezza interna del widget
        decoration: InputDecoration(
          isDense: true, // Fondamentale per rimpicciolire
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: Colors.grey[50],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.amber),
          ),
        ),
        hint: const Text('Seleziona zona', style: TextStyle(fontSize: 14)),
        isExpanded: true,
        // Rimuove la linea sottostante di default dei dropdown
        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        items: [
          const DropdownMenuItem(value: '', child: Text('Tutte le zone', style: TextStyle(fontSize: 14))),
          ...zones.map((zone) => DropdownMenuItem(
                value: zone,
                child: Text(zone, style: const TextStyle(fontSize: 14)),
              )),
        ],
        onChanged: (val) => onZoneChanged(val == '' ? null : val),
      ),
    );
  }
}