import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExternalProfileScreen extends StatefulWidget {
  final String email;
  const ExternalProfileScreen({super.key, required this.email});

  @override
  State<ExternalProfileScreen> createState() => _ExternalProfileScreenState();
}

class _ExternalProfileScreenState extends State<ExternalProfileScreen> {
  String _name = "...";
  String _surname = "...";
  String _age = "...";
  String _gender = "...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // Cerchiamo la stringa salvata con la chiave che usi in registrazione
    final userDataString = prefs.getString('user_data_${widget.email}');

    if (userDataString != null) {
      final Map<String, dynamic> userData = jsonDecode(userDataString);
      
      // Calcolo dell'età dalla data di nascita
      String ageString = "n.d.";
      if (userData['birthDate'] != null) {
        DateTime birthDate = DateTime.parse(userData['birthDate']);
        int age = DateTime.now().year - birthDate.year;
        if (DateTime.now().month < birthDate.month || 
           (DateTime.now().month == birthDate.month && DateTime.now().day < birthDate.day)) {
          age--;
        }
        ageString = age.toString();
      }

      setState(() {
        _name = userData['name'] ?? "Nessun nome";
        _surname = userData['surname'] ?? "Nessun cognome";
        _age = ageString;
        _gender = userData['gender'] ?? "n.d.";
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profilo Partecipante"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
        : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.amber[100],
                  child: const Icon(Icons.person, size: 60, color: Colors.amber),
                ),
                const SizedBox(height: 20),
                
                // Nome e Cognome presi dai dati reali
                Text(
                  "$_name $_surname", 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.email, 
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                
                const SizedBox(height: 30),
                const Divider(indent: 20, endIndent: 20),
                
                _buildInfoTile(Icons.person_outline, "Nome", _name),
                _buildInfoTile(Icons.person_outline, "Cognome", _surname),
                _buildInfoTile(Icons.cake_outlined, "Età", "$_age anni"),
                _buildInfoTile(Icons.transgender_outlined, "Genere", _gender),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.amber),
        ),
        title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}