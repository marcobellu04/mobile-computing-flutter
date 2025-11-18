import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/venue.dart';
import '../providers/venue_provider.dart';

class AddVenueScreen extends StatefulWidget {
  const AddVenueScreen({super.key});

  @override
  _AddVenueScreenState createState() => _AddVenueScreenState();
}

class _AddVenueScreenState extends State<AddVenueScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final venueProvider = Provider.of<VenueProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Aggiungi Struttura")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nome struttura"),
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
              decoration: const InputDecoration(labelText: "Indirizzo"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email struttura"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty ||
                    capacityController.text.isEmpty ||
                    addressController.text.isEmpty ||
                    emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Compila tutti i campi")),
                  );
                  return;
                }

                final newVenue = Venue(
                  id: UniqueKey().toString(),
                  name: nameController.text,
                  capacity: int.parse(capacityController.text),
                  address: addressController.text,
                  email: emailController.text,
                );

                venueProvider.addVenue(newVenue);
                Navigator.pop(context);
              },
              child: const Text("Aggiungi Struttura"),
            ),
          ],
        ),
      ),
    );
  }
}
