import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:geocoding/geocoding.dart';

// Modelli
import '../models/event.dart';

// Provider
import '../providers/event_provider.dart';

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
  final int _maxParticipants = 10;
  
  ListType _listType = ListType.open;
  AgeRestrictionType _ageRestrictionType = AgeRestrictionType.none;
  int? _ageRestrictionValue;

  double? eventLat, eventLng;
  
  List<File> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImages() async {
    final List<XFile> pickedList = await _picker.pickMultiImage();
    if (pickedList.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedList.map((xfile) => File(xfile.path)).toList());
      });
    }
  }

  Future<void> _geocodeAddress() async {
    final raw = _addressController.text.trim();
    if (raw.isEmpty) return;
    
    try {
      final query = '$raw, Roma, Italia'; 
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        setState(() {
          eventLat = locations.first.latitude;
          eventLng = locations.first.longitude;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📍 Posizione confermata!')),
          );
        }
      }
    } catch (e) {
      debugPrint("Errore geocoding: $e");
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
        const SnackBar(content: Text('Compila i campi obbligatori e la data')),
      );
      return;
    }
    
    final newEvent = Event(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDate!,
      zone: _zoneController.text.trim(),
      fullAddress: _addressController.text.trim(),
      ownerEmail: widget.ownerEmail,
      ownerName: widget.ownerName,
      ownerSurname: widget.ownerSurname,
      maxParticipants: _maxParticipants,
      listType: _listType,
      ageRestrictionType: _ageRestrictionType,
      ageRestrictionValue: _ageRestrictionValue,
      participants: [],
      pendingRequests: [],
      venueId: null, // Ora è sempre null poiché abbiamo rimosso la selezione
      lat: eventLat,
      lng: eventLng,
      imagePaths: _imageFiles.map((f) => f.path).toList(), 
    );

    context.read<EventProvider>().addEvent(newEvent);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea Evento', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Foto Multipla
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _imageFiles.isEmpty
                      ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageFiles.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.file(_imageFiles[index], height: 140, width: 140, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _imageFiles.removeAt(index)),
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.close, size: 15, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: _pillInput('Nome Evento *', Icons.title),
                validator: (v) => v!.isEmpty ? 'Inserisci un nome' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _pillInput('Descrizione', Icons.description),
              ),
              const SizedBox(height: 15),

              // Data Selector
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 10),
                      Text(_selectedDate == null 
                          ? 'Data dell\'evento *' 
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _addressController,
                decoration: _pillInput('Indirizzo', Icons.location_on, 
                  suffix: IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.amber),
                    onPressed: _geocodeAddress,
                  )
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _zoneController,
                decoration: _pillInput('Zona (es. Eur, Centro, Trastevere)', Icons.map_outlined),
                validator: (v) => v!.isEmpty ? 'Inserisci una zona per i filtri' : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<ListType>(
                value: _listType,
                decoration: _pillInput('Tipo Lista', Icons.list),
                items: ListType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type == ListType.open ? 'Aperta' : 'Chiusa'),
                )).toList(),
                onChanged: (v) => setState(() => _listType = v!),
              ),
              const SizedBox(height: 15),

              // Gestione Età
              DropdownButtonFormField<AgeRestrictionType>(
                value: _ageRestrictionType,
                decoration: _pillInput('Restrizione Età', Icons.person_search),
                items: const [
                  DropdownMenuItem(value: AgeRestrictionType.none, child: Text('Nessuna')),
                  DropdownMenuItem(value: AgeRestrictionType.over, child: Text('Vietato ai minori (Over)')),
                  DropdownMenuItem(value: AgeRestrictionType.under, child: Text('Solo per giovani (Under)')),
                ],
                onChanged: (v) => setState(() => _ageRestrictionType = v!),
              ),
              if (_ageRestrictionType != AgeRestrictionType.none) ...[
                const SizedBox(height: 10),
                TextFormField(
                  decoration: _pillInput('Inserisci età limite', Icons.cake),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _ageRestrictionValue = int.tryParse(v),
                ),
              ],

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('PUBBLICA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}