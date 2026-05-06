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
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  double? _lat, _lng;

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
    if (addressController.text.isEmpty) return;
    try {
      final locations = await locationFromAddress(addressController.text);
      if (locations.isNotEmpty) {
        setState(() {
          _lat = locations.first.latitude;
          _lng = locations.first.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📍 Posizione trovata!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indirizzo non trovato')));
    }
  }

  void _saveVenue() {
    if (nameController.text.isEmpty || addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Nome e Indirizzo obbligatori")));
      return;
    }

    final newVenue = Venue(
      id: const Uuid().v4(),
      name: nameController.text.trim(),
      ownerEmail: widget.ownerEmail, // Colleghiamo la struttura all'utente
      capacity: int.tryParse(capacityController.text),
      address: addressController.text.trim(),
      phone: phoneController.text.trim(),
      description: descriptionController.text.trim(),
      lat: _lat ?? 41.9028,
      lng: _lng ?? 12.4964,
      imagePath: _imageFile?.path,
    );

    context.read<VenueProvider>().addVenue(newVenue);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuova Struttura"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180, width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100], borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _imageFile == null
                    ? const Icon(Icons.add_a_photo, size: 40, color: Colors.amber)
                    : ClipRRect(borderRadius: BorderRadius.circular(25), child: Image.file(_imageFile!, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: nameController, decoration: _pillInput("Nome", Icons.business)),
            const SizedBox(height: 15),
            TextField(controller: addressController, decoration: _pillInput("Indirizzo", Icons.map, suffix: IconButton(icon: const Icon(Icons.gps_fixed), onPressed: _geocodeAddress))),
            const SizedBox(height: 15),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: _pillInput("Telefono", Icons.phone)),
            const SizedBox(height: 15),
            TextField(controller: capacityController, keyboardType: TextInputType.number, decoration: _pillInput("Capacità", Icons.people)),
            const SizedBox(height: 15),
            TextField(controller: descriptionController, maxLines: 3, decoration: _pillInput("Descrizione", Icons.info_outline)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _saveVenue,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: const Text("SALVA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}