import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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

  // immagine struttura
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _saveVenue() {
    if (nameController.text.isEmpty ||
        capacityController.text.isEmpty ||
        addressController.text.isEmpty ||
        emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compila tutti i campi")),
      );
      return;
    }

    final venueProvider =
        Provider.of<VenueProvider>(context, listen: false);

    final newVenue = Venue(
      id: UniqueKey().toString(),
      name: nameController.text.trim(),
      capacity: int.parse(capacityController.text),
      address: addressController.text.trim(),
      email: emailController.text.trim(),
      // se nel tuo modello Venue aggiungi imagePath/ownerEmail ecc. gestiscili qui:
      // imagePath: _imageFile?.path,
      // ownerEmail: widget.ownerEmail,
      // ownerName: widget.ownerName,
      // ownerSurname: widget.ownerSurname,
    );

    venueProvider.addVenue(newVenue);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aggiungi Struttura")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // BOX IMMAGINE IN ALTO
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
                    ? const Center(
                        child: Text(
                          "Tocca per aggiungere un'immagine della struttura",
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: "Nome struttura"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Capienza"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              decoration:
                  const InputDecoration(labelText: "Indirizzo"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  const InputDecoration(labelText: "Email struttura"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveVenue,
                child: const Text("Aggiungi Struttura"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
