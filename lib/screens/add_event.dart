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
              '📍 Coordinate impostate: ${eventLat!.toStringAsFixed(4)}, ${eventLng!.toStringAsFixed(4)}',
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
        SnackBar(content: Text('Errore geocodifica: $e')),
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
    // Validazione form e data
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila i campi obbligatori e seleziona una data')),
      );
      return;
    }

    // Validazione specifica per l'età se attivata
    if (_ageRestrictionType != AgeRestrictionType.none &&
        (_ageRestrictionValue == null || _ageRestrictionValue! <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un valore valido per l\'età')),
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
      SnackBar(content: Text('✅ Evento "${_nameController.text}" creato!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venues = Provider.of<VenueProvider>(context).venues;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aggiungi Evento'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SEZIONE IMMAGINE ---
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _imageFile == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                              Text('Aggiungi foto evento', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // --- CAMPI TESTO ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome Evento *', border: OutlineInputBorder()),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Campo obbligatorio' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrizione', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 15),

              // --- DATA ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_selectedDate == null 
                  ? 'Nessuna data selezionata' 
                  : 'Data: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                trailing: ElevatedButton(
                  onPressed: _selectDate,
                  child: const Text('Scegli Data'),
                ),
              ),
              const Divider(),

              // --- POSIZIONE ---
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Indirizzo o Luogo (es. EUR, Roma)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.location_searching),
                    onPressed: _geocodeAddress,
                  ),
                ),
                onFieldSubmitted: (_) => _geocodeAddress(),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _zoneController,
                decoration: const InputDecoration(labelText: 'Zona (es. Roma Nord)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              // --- PARTECIPANTI E LISTE ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _maxParticipants.toString(),
                      decoration: const InputDecoration(labelText: 'Max Partecipanti', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _maxParticipants = int.tryParse(v) ?? 10,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<ListType>(
                      value: _listType,
                      decoration: const InputDecoration(labelText: 'Tipo lista', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: ListType.open, child: Text('Aperta')),
                        DropdownMenuItem(value: ListType.closed, child: Text('Chiusa')),
                      ],
                      onChanged: (v) => setState(() => _listType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // --- STRUTTURA ---
              DropdownButtonFormField<String>(
                value: _selectedVenueId,
                decoration: const InputDecoration(labelText: 'Collega a una tua struttura', border: OutlineInputBorder()),
                items: venues.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList(),
                onChanged: (v) => setState(() => _selectedVenueId = v),
              ),
              const SizedBox(height: 20),

              // --- SEZIONE ETÀ (DINAMICA) ---
              const Text("Restrizioni Età", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              DropdownButtonFormField<AgeRestrictionType>(
                value: _ageRestrictionType,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: AgeRestrictionType.none, child: Text('Nessuna restrizione')),
                  DropdownMenuItem(value: AgeRestrictionType.over, child: Text('Età minima (Over)')),
                  DropdownMenuItem(value: AgeRestrictionType.under, child: Text('Età massima (Under)')),
                ],
                onChanged: (v) => setState(() {
                  _ageRestrictionType = v!;
                  if (_ageRestrictionType == AgeRestrictionType.none) _ageRestrictionValue = null;
                }),
              ),
              
              // Campo che appare solo se serve inserire l'età
              if (_ageRestrictionType != AgeRestrictionType.none)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: _ageRestrictionType == AgeRestrictionType.over ? 'Età minima' : 'Età massima',
                      hintText: 'Inserisci numero (es. 18)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.cake),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _ageRestrictionValue = int.tryParse(v)),
                    validator: (v) {
                      if (_ageRestrictionType != AgeRestrictionType.none) {
                        if (v == null || v.isEmpty) return 'Inserisci l\'età';
                        if (int.tryParse(v) == null) return 'Inserisci un numero';
                      }
                      return null;
                    },
                  ),
                ),

              const SizedBox(height: 40),

              // --- TASTO SALVA ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('CREA EVENTO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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