import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:geocoding/geocoding.dart';

import '../models/event.dart';
import '../models/venue.dart';
import '../providers/event_provider.dart';
import '../providers/venue_provider.dart';

class AddEventScreen extends StatefulWidget {
  final String ownerEmail;
  final String ownerName;
  final String ownerSurname;

  const AddEventScreen({
    super.key,
    required this.ownerEmail,
    required this.ownerName,
    required this.ownerSurname,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  DateTime? _selectedDate;
  int _maxParticipants = 10;
  ListType _listType = ListType.open;
  String? _selectedVenueId;

  AgeRestrictionType _ageRestrictionType = AgeRestrictionType.none;
  int? _ageRestrictionValue;

  double? eventLat, eventLng;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _geocodeAddress() async {
    final raw = _addressController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci indirizzo!')),
      );
      return;
    }

    try {
      final query = '$raw, Roma, Italia'; 
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        setState(() {
          eventLat = loc.latitude;
          eventLng = loc.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📍 ${eventLat!.toStringAsFixed(4)}, ${eventLng!.toStringAsFixed(4)}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Indirizzo non trovato')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  void _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi e seleziona data')),
      );
      return;
    }

    if (_ageRestrictionType != AgeRestrictionType.none &&
        (_ageRestrictionValue == null || _ageRestrictionValue! <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valore età non valido')),
      );
      return;
    }

    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    final newEvent = Event(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: _selectedDate!,
      zone: _zoneController.text.trim().isEmpty ? null : _zoneController.text.trim(),
      fullAddress: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      ownerEmail: widget.ownerEmail,
      ownerName: widget.ownerName,
      ownerSurname: widget.ownerSurname,
      maxParticipants: _maxParticipants,
      ageRestrictionType: _ageRestrictionType,
      ageRestrictionValue: _ageRestrictionValue,
      participants: [],
      pendingRequests: [],
      listType: _listType,
      venueId: _selectedVenueId,
      lat: eventLat,
      lng: eventLng,
      imagePath: _imageFile?.path,
    );

    eventProvider.addEvent(newEvent);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ ${_nameController.text} salvato')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venues = Provider.of<VenueProvider>(context).venues;

    return Scaffold(
      appBar: AppBar(title: const Text('Aggiungi Evento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 50, color: Colors.white70),
                            Text('Aggiungi foto',
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome Evento *'),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Obbligatorio' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrizione'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _selectDate,
                  child: Text(
                    _selectedDate == null
                        ? 'Seleziona data *'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Indirizzo (es. EUR, Colosseo)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_searching),
                  onPressed: _geocodeAddress,
                ),
              ),
              onFieldSubmitted: (_) => _geocodeAddress(),
            ),
            TextFormField(
              controller: _zoneController,
              decoration: const InputDecoration(labelText: 'Zona (opzionale)'),
            ),
            TextFormField(
              initialValue: _maxParticipants.toString(),
              decoration:
                  const InputDecoration(labelText: 'Numero massimo partecipanti'),
              keyboardType: TextInputType.number,
              onChanged: (v) => _maxParticipants = int.tryParse(v) ?? 10,
            ),
            DropdownButtonFormField<ListType>(
              value: _listType,
              decoration: const InputDecoration(labelText: 'Tipo lista'),
              items: const [
                DropdownMenuItem(value: ListType.open, child: Text('Lista Aperta')),
                DropdownMenuItem(value: ListType.closed, child: Text('Lista Chiusa')),
              ],
              onChanged: (v) => setState(() => _listType = v!),
            ),
            DropdownButtonFormField<String>(
              value: _selectedVenueId,
              decoration: const InputDecoration(labelText: 'Struttura'),
              items: venues.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList(),
              onChanged: (v) => setState(() => _selectedVenueId = v),
            ),
            DropdownButtonFormField<AgeRestrictionType>(
              value: _ageRestrictionType,
              decoration: const InputDecoration(labelText: 'Restrizione età'),
              items: const [
                DropdownMenuItem(value: AgeRestrictionType.none, child: Text('Nessuna')),
                DropdownMenuItem(value: AgeRestrictionType.over, child: Text('Età minima')),
                DropdownMenuItem(value: AgeRestrictionType.under, child: Text('Età massima')),
              ],
              onChanged: (v) => setState(() => _ageRestrictionType = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _saveEvent, child: const Text('Salva Evento')),
            ),
          ]),
        ),
      ),
    );
  }
}