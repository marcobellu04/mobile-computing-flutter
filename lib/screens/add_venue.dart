import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:geocoding/geocoding.dart';

import '../models/venue.dart';
import '../providers/venue_provider.dart';

class AddVenueScreen extends StatefulWidget {
  final String ownerEmail;
  final String ownerName;
  final String ownerSurname;

  const AddVenueScreen({
    super.key,
    required this.ownerEmail,
    required this.ownerName,
    required this.ownerSurname,
  });

  @override
  State<AddVenueScreen> createState() => _AddVenueScreenState();
}

class _AddVenueScreenState extends State<AddVenueScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  double? _lat, _lng;

  // --- STILE A PILLOLA COERENTE ---
  InputDecoration _pillInput(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      suffixIcon: suffix,
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

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _geocodeAddress() async {
    if (addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inserisci un indirizzo!')));
      return;
    }
    try {
      final locations = await locationFromAddress(addressController.text); 
      if (locations.isNotEmpty) {
        setState(() {
          _lat = locations.first.latitude;
          _lng = locations.first.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📍 Struttura localizzata sulla mappa!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Indirizzo non trovato: $e')),
      );
    }
  }

  void _saveVenue() {
    if (nameController.text.isEmpty || capacityController.text.isEmpty ||
        addressController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Compila tutti i campi")),
      );
      return;
    }

    final venueProvider = Provider.of<VenueProvider>(context, listen: false);

    final newVenue = Venue(
      id: const Uuid().v4(),
      name: nameController.text.trim(),
      capacity: int.parse(capacityController.text),
      address: addressController.text.trim(),
      email: emailController.text.trim(),
      lat: _lat ?? 41.9028,
      lng: _lng ?? 12.4964,
      imagePath: _imageFile?.path,
    );

    venueProvider.addVenue(newVenue);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ ${newVenue.name} aggiunta!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aggiungi Struttura", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- BOX FOTO ---
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _imageFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_business_outlined, size: 45, color: Colors.amber),
                          Text('Aggiungi Foto Struttura', style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 25),

            // --- CAMPI TESTO ---
            TextField(
              controller: nameController, 
              decoration: _pillInput("Nome Struttura", Icons.business_outlined),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: _pillInput("Capienza Massima", Icons.people_outline),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: addressController,
              decoration: _pillInput(
                "Indirizzo", 
                Icons.map_outlined,
                suffix: IconButton(
                  icon: const Icon(Icons.gps_fixed, color: Colors.amber),
                  onPressed: _geocodeAddress,
                ),
              ),
              onSubmitted: (_) => _geocodeAddress(),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _pillInput("Email di contatto", Icons.alternate_email),
            ),
            const SizedBox(height: 35),

            // --- TASTO SALVA ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _saveVenue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 2,
                ),
                child: const Text(
                  "SALVA STRUTTURA", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}