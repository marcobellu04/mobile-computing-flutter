import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  DateTime? _birthDate;
  String? _gender;

  Future<List<Map<String, dynamic>>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersString = prefs.getString('users');
    if (usersString == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(usersString));
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('users', jsonEncode(users));
  }

  Future<void> _saveProfile({
    required String email,
    required String name,
    required String surname,
    required DateTime birthDate,
    required String gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final profileMap = {
      'email': email,
      'name': name,
      'surname': surname,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
    };
    await prefs.setString('user_data_$email', jsonEncode(profileMap));
  }

  Future<void> _pickBirthDate() async {
    final initialDate = _birthDate ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        _birthDate == null ||
        _gender == null) {
      _showError('Compila tutti i campi');
      return;
    }

    final users = await _getUsers();
    if (users.any((u) => u['email'] == email)) {
      _showError('Utente già registrato');
      return;
    }

    users.add({
      'name': name,
      'surname': surname,
      'email': email,
      'password': password,
    });
    await _saveUsers(users);

    await _saveProfile(
      email: email,
      name: name,
      surname: surname,
      birthDate: _birthDate!,
      gender: _gender!,
    );

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      'Log in',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),

                const Text('Name',
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    hintText: 'Nome',
                    hintStyle: TextStyle(color: Colors.black38),
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Surname',
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _surnameController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    hintText: 'Cognome',
                    hintStyle: TextStyle(color: Colors.black38),
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Date of birth',
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _birthDate == null
                        ? 'Seleziona data di nascita'
                        : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  trailing:
                      const Icon(Icons.calendar_today, color: Colors.black54),
                  onTap: _pickBirthDate,
                ),
                const SizedBox(height: 24),

                const Text('Gender',
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (val) => setState(() => _gender = val),
                ),
                const SizedBox(height: 24),

                const Text('Your Email',
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    hintText: 'hello@gmail.com',
                    hintStyle: TextStyle(color: Colors.black38),
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Password',
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(color: Colors.black38),
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Sign up',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      'Hai già un account? Accedi',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
