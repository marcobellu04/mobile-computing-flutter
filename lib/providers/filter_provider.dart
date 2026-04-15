import 'package:flutter/material.dart';
import '../models/event.dart';

class FilterProvider extends ChangeNotifier {
  String? _selectedZone;
  AgeRestrictionType? _ageFilterType = AgeRestrictionType.none;
  int? _ageFilterValue;
  DateTime? _dateFilter;

  // Getters
  String? get selectedZone => _selectedZone;
  AgeRestrictionType? get ageFilterType => _ageFilterType;
  int? get ageFilterValue => _ageFilterValue;
  DateTime? get dateFilter => _dateFilter;

  // Setters
  void setSelectedZone(String? zone) {
    _selectedZone = zone;
    notifyListeners();
  }

  void setAgeFilterType(AgeRestrictionType? type) {
    _ageFilterType = type;
    notifyListeners();
  }

  void setAgeFilterValue(int? value) {
    _ageFilterValue = value;
    notifyListeners();
  }

  void setDateFilter(DateTime? date) {
    _dateFilter = date;
    notifyListeners();
  }

  // LOGICA DI FILTRAGGIO: Questa è la parte nuova che "pulisce" la lista
  List<Event> applyFilters(List<Event> allEvents) {
    print("FILTRO ATTIVO: Tipo: $_ageFilterType, Valore: $_ageFilterValue");
    return allEvents.where((event) {
      // 1. Filtro per Zona
      if (_selectedZone != null && _selectedZone != "Tutte" && _selectedZone!.isNotEmpty) {
        if (event.zone != _selectedZone) return false;
      }

      // 2. Filtro per Data (confronto solo giorno/mese/anno)
      if (_dateFilter != null) {
        if (event.date.year != _dateFilter!.year ||
            event.date.month != _dateFilter!.month ||
            event.date.day != _dateFilter!.day) {
          return false;
        }
      }

  // 3. Filtro per Età
if (_ageFilterType != AgeRestrictionType.none) {
  // Se l'utente sta cercando un tipo di evento (es. Over) ma l'evento è di un altro tipo (es. Under o Nessuno)
  if (event.ageRestrictionType != _ageFilterType) return false;

  // Se l'utente ha inserito anche un valore numerico (es. 18)
  if (_ageFilterValue != null) {
    if (_ageFilterType == AgeRestrictionType.over) {
      // Mostra solo eventi Over che siano ALMENO l'età cercata (o superiore)
      // Esempio: Cerco Over 18 -> Vedo Over 18, Over 20...
      if ((event.ageRestrictionValue ?? 0) < _ageFilterValue!) return false;
    } 
    else if (_ageFilterType == AgeRestrictionType.under) {
      // Mostra solo eventi Under che non superino l'età cercata
      if ((event.ageRestrictionValue ?? 99) > _ageFilterValue!) return false;
    }
  }
}

      return true;
    }).toList();
  }

  void clearAll() {
    _selectedZone = null;
    _ageFilterType = AgeRestrictionType.none;
    _ageFilterValue = null;
    _dateFilter = null;
    notifyListeners();
  }

  Map<String, dynamic> toMap() => {
        'zone': _selectedZone,
        'ageType': _ageFilterType?.index ?? 0,
        'ageValue': _ageFilterValue,
        'dateFilter': _dateFilter?.toIso8601String(),
      };

  void loadFromMap(Map<String, dynamic> map) {
    _selectedZone = map['zone'];
    _ageFilterType = AgeRestrictionType.values[map['ageType'] ?? 0];
    _ageFilterValue = map['ageValue'];
    if (map['dateFilter'] != null) {
      _dateFilter = DateTime.tryParse(map['dateFilter']);
    } else {
      _dateFilter = null;
    }
    notifyListeners();
  }
}