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
    // Testo dinamico per la pillola
    String label = selectedAgeType == AgeRestrictionType.none 
        ? "Età" 
        : "${selectedAgeType == AgeRestrictionType.under ? 'Under' : 'Over'} ${ageValue ?? ''}";

    return ActionChip(
      avatar: Icon(
        Icons.person_search, 
        size: 16, 
        color: selectedAgeType != AgeRestrictionType.none ? Colors.black : Colors.grey
      ),
      label: Text(label),
      onPressed: () => _showAgePicker(context),
      backgroundColor: selectedAgeType != AgeRestrictionType.none ? Colors.amber[100] : Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: selectedAgeType != AgeRestrictionType.none ? Colors.amber : Colors.transparent),
    );
  }

  void _showAgePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permette al foglio di salire sopra la tastiera
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          // Questo padding dinamico spinge il contenuto sopra la tastiera
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
            top: 20, 
            left: 20, 
            right: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Il pannello occupa solo lo spazio necessario
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filtra per Età", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Menu Under/Over
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<AgeRestrictionType>(
                      initialValue: selectedAgeType,
                      decoration: InputDecoration(
                        labelText: "Tipo",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: AgeRestrictionType.values.map((t) {
                        return DropdownMenuItem(
                          value: t, 
                          child: Text(t == AgeRestrictionType.none ? "Nessuno" : t.name.toUpperCase())
                        );
                      }).toList(),
                      onChanged: (v) => onAgeTypeChanged(v),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Input Numerico
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: ageValue?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Anni",
                        hintText: "es. 18",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => onAgeValueChanged(int.tryParse(v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Bottone di conferma per chiudere
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("APPLICA FILTRO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}