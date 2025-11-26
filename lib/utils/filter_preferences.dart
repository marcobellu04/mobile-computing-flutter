import 'package:shared_preferences/shared_preferences.dart';

class FilterPreferences {
  static const _keyZone = 'filter_zone';
  static const _keyAgeType = 'filter_age_type';
  static const _keyAgeValue = 'filter_age_value';
  static const _keyDate = 'filter_date';

  Future<void> saveFilters(String? zone, int ageTypeIndex, int? ageValue, DateTime? date) async {
    final prefs = await SharedPreferences.getInstance();
    if (zone == null) {
      await prefs.remove(_keyZone);
    } else {
      await prefs.setString(_keyZone, zone);
    }
    await prefs.setInt(_keyAgeType, ageTypeIndex);
    if (ageValue == null) {
      await prefs.remove(_keyAgeValue);
    } else {
      await prefs.setInt(_keyAgeValue, ageValue);
    }
    if (date == null) {
      await prefs.remove(_keyDate);
    } else {
      await prefs.setString(_keyDate, date.toIso8601String());
    }
  }

  Future<Map<String, dynamic>> loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final zone = prefs.getString(_keyZone);
    final ageType = prefs.getInt(_keyAgeType) ?? 0;
    final ageValue = prefs.getInt(_keyAgeValue);
    DateTime? date;
    if (prefs.containsKey(_keyDate)) {
      date = DateTime.tryParse(prefs.getString(_keyDate)!);
    }
    return {
      'zone': zone,
      'ageType': ageType,
      'ageValue': ageValue,
      'dateFilter': date,
    };
  }
}
