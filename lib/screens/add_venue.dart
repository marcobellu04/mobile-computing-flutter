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

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _geocodeAddress() async {
    try {
      final locations = await locationFromAddress(addressController.text); 
      if (locations.isNotEmpty) {
        setState(() {
          _lat = locations.first.latitude;
          _lng = locations.first.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📍 ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}')),
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
      imagePath: _imageFile?.path, // Mantengo questo come nel tuo originale
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
      appBar: AppBar(title: const Text("📍 Aggiungi Venue")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: _imageFile == null
                  ? const Icon(Icons.add_photo_alternate, size: 50, color: Colors.white70)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nome")),
          TextField(
            controller: capacityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Capienza"),
          ),
          TextField(
            controller: addressController,
            decoration: const InputDecoration(labelText: "Indirizzo", suffixIcon: Icon(Icons.map)),
          ),
          TextButton(onPressed: _geocodeAddress, child: const Text('Trova coordinate')),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _saveVenue, child: const Text("Salva Venue")),
          ),
        ]),
      ),
    );
  }
}