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
      if (_ageFilterType != AgeRestrictionType.none && _ageFilterValue != null) {
        if (event.ageRestrictionType == AgeRestrictionType.over) {
          if (_ageFilterValue! < (event.ageRestrictionValue ?? 0)) return false;
        } else if (event.ageRestrictionType == AgeRestrictionType.under) {
          if (_ageFilterValue! > (event.ageRestrictionValue ?? 99)) return false;
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