import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

Future<User?> loadUserFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final userDataString = prefs.getString('user_data');
  if (userDataString == null) return null;
  final Map<String, dynamic> userMap = jsonDecode(userDataString);
  return User.fromMap(userMap);
}
