import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // 1. Impostiamo di default a false (Light Mode)
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // 2. Forza il caricamento a false, ignorando vecchi salvataggi "true"
    _isDarkMode = false; 
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    // 3. Disabilitiamo il toggle: non farà più nulla o puoi usarlo 
    // per forzare comunque il false se richiamato per errore
    _isDarkMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', false);
    notifyListeners();
  }
}