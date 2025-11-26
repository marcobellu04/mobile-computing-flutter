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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<AgeRestrictionType>(
            value: selectedAgeType,
            decoration: const InputDecoration(labelText: 'Filtro età'),
            items: AgeRestrictionType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type == AgeRestrictionType.none
                    ? 'Nessun filtro'
                    : type == AgeRestrictionType.under
                        ? 'Under'
                        : 'Over'),
              );
            }).toList(),
            onChanged: onAgeTypeChanged,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: TextFormField(
            initialValue: ageValue?.toString(),
            decoration: const InputDecoration(labelText: 'Età'),
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final number = int.tryParse(val);
              onAgeValueChanged(number);
            },
          ),
        ),
      ],
    );
  }
}
