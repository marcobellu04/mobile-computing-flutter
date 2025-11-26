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
    return DropdownButtonFormField<String>(
      value: selectedZone,
      hint: const Text('Seleziona zona'),
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: '', child: Text('Tutte le zone')),
        ...zones.map((zone) => DropdownMenuItem(value: zone, child: Text(zone))),
      ],
      onChanged: (val) => onZoneChanged(val == '' ? null : val),
    );
  }
}
