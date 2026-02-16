import 'dart:io'; // Importante per File
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Importa image_picker
import 'dart:convert';
import '../models/user.dart';

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
  String? _currentUserEmail;
  
  // Variabili per l'immagine
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserEmailAndData();
  }

  Future<void> _loadUserEmailAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    setState(() { _currentUserEmail = email; });

    if (email == null) {
      _initEmptyControllers();
      return;
    }

    // Carica immagine salvata localmente (se presente)
    final savedImagePath = prefs.getString('user_image_$email');
    if (savedImagePath != null) {
      setState(() { _imageFile = File(savedImagePath); });
    }

    final jsonString = prefs.getString('user_data_$email');
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
      _initEmptyControllers();
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      setState(() { _imageFile = File(picked.path); });
    }
  }

  void _initEmptyControllers() {
    setState(() {
      _nameController = TextEditingController();
      _surnameController = TextEditingController();
      _emailController = TextEditingController();
      _birthDate = null;
      _gender = null;
      _loading = false;
    });
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate() && _birthDate != null && _gender != null && _currentUserEmail != null) {
      final user = User(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _currentUserEmail!,
        birthDate: _birthDate!,
        gender: _gender!,
      );
      
      final prefs = await SharedPreferences.getInstance();
      
      // Salva dati utente
      final jsonString = jsonEncode(user.toMap());
      await prefs.setString('user_data_$_currentUserEmail', jsonString);
      
      // Salva percorso immagine
      if (_imageFile != null) {
        await prefs.setString('user_image_$_currentUserEmail', _imageFile!.path);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilo salvato con successo')),
      );
      if (Navigator.canPop(context)) Navigator.pop(context, true);
    }
  }

  // ... _pickBirthDate rimane uguale ...
  Future<void> _pickBirthDate() async {
    final initialDate = _birthDate ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Profilo utente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // WIDGET FOTO PROFILO
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null ? const Icon(Icons.camera_alt, size: 40) : null,
                      ),
                      if (_imageFile != null)
                        const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 15, backgroundColor: Colors.amber, child: Icon(Icons.edit, size: 15, color: Colors.black))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome')),
              TextFormField(controller: _surnameController, decoration: const InputDecoration(labelText: 'Cognome')),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), readOnly: true),
              const SizedBox(height: 20),
              ListTile(
                title: Text(_birthDate == null ? 'Seleziona data di nascita' : 'Data: ${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickBirthDate,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Genere'),
                value: _gender,
                items: ['male', 'female', 'other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _gender = val),
              ),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _saveUserData, child: const Text('Salva')),
            ],
          ),
        ),
      ),
    );
  }
}