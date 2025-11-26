import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/user_profile_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<List<Map<String, dynamic>>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersString = prefs.getString('users');
    if (usersString == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(usersString));
  }

  Future<void> _saveLoggedInUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  Future<bool> _profileIncomplete(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data_$email');
    if (userDataString == null) return true;
    try {
      final userMap = jsonDecode(userDataString);
      if (userMap['name'] != null &&
          userMap['name'].toString().isNotEmpty &&
          userMap['surname'] != null &&
          userMap['surname'].toString().isNotEmpty &&
          userMap['email'] != null &&
          userMap['email'].toString().isNotEmpty &&
          userMap['birthDate'] != null &&
          userMap['gender'] != null) {
        return false;
      }
    } catch (_) {}
    return true;
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Compila tutti i campi');
      return;
    }

    final users = await _getUsers();
    final user = users.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (user.isEmpty) {
      _showError('Email o password errati');
      return;
    }

    await _saveLoggedInUser(email);

    if (await _profileIncomplete(email)) {
      if (!mounted) return;
      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const UserProfilePage()),
      );
      if (completed != true) {
        _showError('Devi completare il profilo per continuare');
        return;
      }
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Accedi'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text('Non hai un account? Registrati'),
            ),
          ],
        ),
      ),
    );
  }
}
