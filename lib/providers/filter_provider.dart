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

  void clearAll() {
    _selectedZone = null;
    _ageFilterType = AgeRestrictionType.none;
    _ageFilterValue = null;
    _dateFilter = null;
    notifyListeners();
  }
}
