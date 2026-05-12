import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
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
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserEmailAndData();
  }

  InputDecoration _pillInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.amber, width: 2),
      ),
    );
  }

  Future<void> _loadUserEmailAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    setState(() { _currentUserEmail = email; });

    if (email == null) {
      _initEmptyControllers();
      return;
    }

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

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      setState(() { _imageFile = File(picked.path); });
    }
  }

  Future<void> _pickBirthDate() async {
    final initialDate = _birthDate ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.amber, onPrimary: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _birthDate = picked);
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
      final jsonString = jsonEncode(user.toMap());
      await prefs.setString('user_data_$_currentUserEmail', jsonString);
      
      if (_imageFile != null) {
        await prefs.setString('user_image_$_currentUserEmail', _imageFile!.path);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilo salvato con successo')),
      );
      
      // Torniamo indietro notificando che i dati sono cambiati
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.amber)));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profilo Personale', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- FOTO PROFILO ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                          child: _imageFile == null 
                              ? const Icon(Icons.person, size: 60, color: Colors.grey) 
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.amber,
                          child: Icon(
                            _imageFile == null ? Icons.add_a_photo : Icons.edit,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- CAMPI TESTO ---
              TextFormField(
                controller: _nameController, 
                decoration: _pillInput('Nome', Icons.person_outline),
                validator: (v) => v!.isEmpty ? 'Inserisci il nome' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _surnameController, 
                decoration: _pillInput('Cognome', Icons.person_outline),
                validator: (v) => v!.isEmpty ? 'Inserisci il cognome' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _emailController, 
                decoration: _pillInput('Email (sola lettura)', Icons.email_outlined),
                readOnly: true,
              ),
              const SizedBox(height: 15),

              // --- DATA DI NASCITA ---
              InkWell(
                onTap: _pickBirthDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        _birthDate == null 
                          ? 'Data di nascita' 
                          : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                        style: TextStyle(
                          color: _birthDate == null ? Colors.grey[700] : Colors.black,
                          fontSize: 16
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // --- GENERE ---
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: _pillInput('Genere', Icons.wc_outlined),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Uomo')),
                  DropdownMenuItem(value: 'female', child: Text('Donna')),
                  DropdownMenuItem(value: 'other', child: Text('Altro')),
                ],
                onChanged: (val) => setState(() => _gender = val),
                validator: (v) => v == null ? 'Seleziona il genere' : null,
              ),

              const SizedBox(height: 40),

              // --- TASTO SALVA ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                  ),
                  child: const Text('SALVA MODIFICHE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}