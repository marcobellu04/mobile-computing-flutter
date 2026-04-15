import 'package:flutter/material.dart';
import '../models/event.dart';

class FilterAge extends StatelessWidget {
  final AgeRestrictionType selectedAgeType;
  final int? ageValue;
  final ValueChanged<AgeRestrictionType?> onAgeTypeChanged;
  final ValueChanged<int?> onAgeValueChanged;

  const FilterAge({
    super.key,
    required this.selectedAgeType,
    required this.ageValue,
    required this.onAgeTypeChanged,
    required this.onAgeValueChanged,
  });

 // In lib/widgets/filter_age.dart
@override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<AgeRestrictionType>(
            value: selectedAgeType,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Filtro età',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: AgeRestrictionType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type == AgeRestrictionType.none
                    ? 'Nessun filtro'
                    : type == AgeRestrictionType.under ? 'Under' : 'Over'),
              );
            }).toList(),
            onChanged: onAgeTypeChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            initialValue: ageValue?.toString(),
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Età',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) => onAgeValueChanged(int.tryParse(val)),
          ),
        ),
      ],
    ),
  );
}
}