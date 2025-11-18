import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/user.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  DateTime? birthDate;
  String? gender;

  Future<void> _selectBirthDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || birthDate == null || gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi correttamente')),
      );
      return;
    }

    final user = User(
      email: emailController.text.trim(),
      name: nameController.text.trim(),
      surname: surnameController.text.trim(),
      birthDate: birthDate!,
      gender: gender!,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_data', jsonEncode(user.toMap()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registrazione completata!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione Utente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Inserisci una email valida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: surnameController,
                decoration: const InputDecoration(labelText: 'Cognome'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il cognome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(birthDate == null
                    ? 'Seleziona data di nascita'
                    : 'Data di nascita: ${birthDate!.day}/${birthDate!.month}/${birthDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectBirthDate(context),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: gender,
                decoration: const InputDecoration(labelText: 'Genere'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Maschile')),
                  DropdownMenuItem(value: 'female', child: Text('Femminile')),
                  DropdownMenuItem(value: 'other', child: Text('Altro')),
                ],
                onChanged: (value) {
                  setState(() {
                    gender = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Seleziona un genere' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Registrati'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
