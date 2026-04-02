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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _geocodeAddress() async {
    final raw = _addressController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inserisci indirizzo!')));
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
          SnackBar(content: Text('📍 Posizione localizzata sulla mappa!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore localizzazione: $e')));
    }
  }

  void _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.amber, onPrimary: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compila i campi e scegli una data')));
      return;
    }
    
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final newEvent = Event(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      date: _selectedDate!,
      zone: _zoneController.text.trim().isEmpty ? null : _zoneController.text.trim(),
      fullAddress: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
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
  }

  @override
  Widget build(BuildContext context) {
    final venues = Provider.of<VenueProvider>(context).venues;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea Nuovo Evento', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- SEZIONE FOTO ---
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
                            Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.amber),
                            Text('Aggiungi Foto Copertina', style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 25),

              TextFormField(
                controller: _nameController,
                decoration: _pillInput('Nome Evento *', Icons.local_activity_outlined),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Obbligatorio' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: _pillInput('Descrizione', Icons.notes_rounded),
              ),
              const SizedBox(height: 15),

              // --- DATA ---
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null 
                          ? 'Scegli Data *' 
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(color: _selectedDate == null ? Colors.grey[700] : Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // --- INDIRIZZO E LOCALIZZAZIONE ---
              TextFormField(
                controller: _addressController,
                decoration: _pillInput(
                  'Indirizzo (es. Via del Corso)', 
                  Icons.location_on_outlined,
                  suffix: IconButton(
                    icon: const Icon(Icons.gps_fixed, color: Colors.amber),
                    onPressed: _geocodeAddress,
                  ),
                ),
                onFieldSubmitted: (_) => _geocodeAddress(),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _zoneController,
                decoration: _pillInput('Zona (es. Roma Sud)', Icons.map_outlined),
              ),
              const SizedBox(height: 15),

              // --- PARTECIPANTI E TIPO LISTA ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _maxParticipants.toString(),
                      decoration: _pillInput('Max Persone', Icons.people_outline),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _maxParticipants = int.tryParse(v) ?? 10,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<ListType>(
                      value: _listType,
                      decoration: _pillInput('Lista', Icons.list_alt),
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
                isExpanded: true,
                decoration: _pillInput('Collega Struttura', Icons.business_outlined),
                items: venues.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList(),
                onChanged: (v) => setState(() => _selectedVenueId = v),
              ),
              const SizedBox(height: 15),

              // --- ETÀ ---
              DropdownButtonFormField<AgeRestrictionType>(
                value: _ageRestrictionType,
                decoration: _pillInput('Restrizioni Età', Icons.how_to_reg_outlined),
                items: const [
                  DropdownMenuItem(value: AgeRestrictionType.none, child: Text('Nessuna')),
                  DropdownMenuItem(value: AgeRestrictionType.over, child: Text('Over (Minima)')),
                  DropdownMenuItem(value: AgeRestrictionType.under, child: Text('Under (Massima)')),
                ],
                onChanged: (v) => setState(() {
                  _ageRestrictionType = v!;
                  if (_ageRestrictionType == AgeRestrictionType.none) _ageRestrictionValue = null;
                }),
              ),
              if (_ageRestrictionType != AgeRestrictionType.none) ...[
                const SizedBox(height: 15),
                TextFormField(
                  decoration: _pillInput('Inserisci Età', Icons.cake_outlined),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => _ageRestrictionValue = int.tryParse(v)),
                ),
              ],

              const SizedBox(height: 35),

              // --- TASTO FINALE ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('PUBBLICA ORA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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