import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:my_first_app/models/user.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  DateTime? _birthDate;
  String? _gender;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user_data');
    if (jsonString != null) {
      final Map<String, dynamic> userMap = jsonDecode(jsonString);
      final user = User.fromMap(userMap);
      setState(() {
        _nameController = TextEditingController(text: user.name);
        _surnameController = TextEditingController(text: user.surname);
        _emailController = TextEditingController(text: user.email);
        _birthDate = user.birthDate;
        _gender = user.gender;
        _loading = false;
      });
    } else {
      // Default controllers if no data saved
      setState(() {
        _nameController = TextEditingController();
        _surnameController = TextEditingController();
        _emailController = TextEditingController();
        _birthDate = null;
        _gender = null;
        _loading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate() && _birthDate != null && _gender != null) {
      final user = User(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _emailController.text.trim(),
        birthDate: _birthDate!,
        gender: _gender!,
      );
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(user.toMap());
      await prefs.setString('user_data', jsonString);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profilo salvato con successo')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compila tutti i campi richiesta')));
    }
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profilo utente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => (value == null || value.isEmpty) ? 'Inserisci il nome' : null,
              ),
              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(labelText: 'Cognome'),
                validator: (value) => (value == null || value.isEmpty) ? 'Inserisci il cognome' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || value.isEmpty) ? 'Inserisci l\'email' : null,
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text(_birthDate == null
                    ? 'Seleziona data di nascita'
                    : 'Data di nascita: ${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickBirthDate,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Genere'),
                value: _gender,
                items: ['male', 'female', 'other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _gender = val;
                  });
                },
                validator: (value) => value == null ? 'Seleziona un genere' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveUserData,
                child: const Text('Salva'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
