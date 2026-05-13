import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:geocoding/geocoding.dart';

import '../models/event.dart';
import '../providers/event_provider.dart';
import '../providers/booking_provider.dart'; // Aggiunto per recuperare le strutture

class AddEventScreen extends StatefulWidget {
  final String ownerEmail;
  final String ownerName;
  final String ownerSurname;
  final String? approvedVenueName;
  final String? approvedVenueAddress;

  const AddEventScreen({
    super.key,
    required this.ownerEmail,
    required this.ownerName,
    required this.ownerSurname,
    this.approvedVenueName,
    this.approvedVenueAddress,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  late TextEditingController _addressController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final int _maxParticipants = 10;
  
  ListType _listType = ListType.open;
  final AgeRestrictionType _ageRestrictionType = AgeRestrictionType.none;
  int? _ageRestrictionValue;

  double? eventLat, eventLng;
  
  // Variabile per la struttura scelta opzionalmente
  String? _selectedVenueName;

  final List<File> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.approvedVenueName != null ? "Evento presso ${widget.approvedVenueName}" : ""
    );
    _addressController = TextEditingController(text: widget.approvedVenueAddress ?? "");
    
    // Se arrivo con una struttura già passata, la imposto come scelta
    _selectedVenueName = widget.approvedVenueName;

    if (widget.approvedVenueAddress != null) {
      _geocodeAddress();
    }
  }

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
      }
    } catch (e) {
      debugPrint("Errore geocoding: $e");
    }
  }

  void _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compila i campi obbligatori, data e ora')));
      return;
    }
    
    final finalDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
    
    final newEvent = Event(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      date: finalDateTime,
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
      // Salva la struttura se selezionata o passata dal widget
      venueId: _selectedVenueName, 
      lat: eventLat,
      lng: eventLng,
      imagePaths: _imageFiles.map((f) => f.path).toList(),
    );

    context.read<EventProvider>().addEvent(newEvent);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Recupero le richieste approvate dell'utente
    final bookingProvider = context.watch<BookingProvider>();
    final approvedRequests = bookingProvider.requests
        .where((r) => r.senderEmail == widget.ownerEmail && (r.status == 'approved' || r.status == 'accepted'))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Crea Evento', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 160, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                  child: _imageFiles.isEmpty
                      ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageFiles.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Stack(
                              children: [
                                ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_imageFiles[index], height: 140, width: 140, fit: BoxFit.cover)),
                                Positioned(right: 0, top: 0, child: GestureDetector(onTap: () => setState(() => _imageFiles.removeAt(index)), child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 15, color: Colors.white)))),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                // Sola lettura solo se è già stata passata una struttura specifica
                readOnly: widget.approvedVenueName != null,
                decoration: _pillInput('Nome Evento *', Icons.title),
                validator: (v) => v!.isEmpty ? 'Inserisci un nome' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(controller: _descriptionController, maxLines: 3, decoration: _pillInput('Descrizione', Icons.description)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: InkWell(onTap: _selectDate, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(30)), child: Row(children: [const Icon(Icons.calendar_today, size: 18, color: Colors.grey), const SizedBox(width: 10), Text(_selectedDate == null ? 'Data *' : '${_selectedDate!.day}/${_selectedDate!.month}')])))),
                  const SizedBox(width: 10),
                  Expanded(child: InkWell(onTap: _selectTime, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(30)), child: Row(children: [const Icon(Icons.access_time, size: 18, color: Colors.grey), const SizedBox(width: 10), Text(_selectedTime == null ? 'Ora *' : _selectedTime!.format(context))])))),
                ],
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _addressController,
                // Sola lettura solo se la struttura è già bloccata
                readOnly: widget.approvedVenueAddress != null || (_selectedVenueName != null && _selectedVenueName!.isNotEmpty),
                decoration: _pillInput(
                  'Indirizzo',
                  Icons.location_on,
                  suffix: (widget.approvedVenueAddress == null && _selectedVenueName == null)
                    ? IconButton(icon: const Icon(Icons.check_circle, color: Colors.amber), onPressed: _geocodeAddress)
                    : const Icon(Icons.verified, color: Colors.green),
                ),
                validator: (v) => v!.isEmpty ? 'L\'indirizzo è obbligatorio' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(controller: _zoneController, decoration: _pillInput('Zona (es. Eur, Centro)', Icons.map_outlined), validator: (v) => v!.isEmpty ? 'Inserisci una zona' : null),
              const SizedBox(height: 15),
              DropdownButtonFormField<ListType>(value: _listType, decoration: _pillInput('Tipo Lista', Icons.list), items: ListType.values.map((type) => DropdownMenuItem(value: type, child: Text(type == ListType.open ? 'Aperta' : 'Chiusa'))).toList(), onChanged: (v) => setState(() => _listType = v!)),
              
              const SizedBox(height: 15),
              
              // --- NUOVA OPZIONE STRUTTURA IN FONDO ---
              DropdownButtonFormField<String?>(
                value: _selectedVenueName,
                decoration: _pillInput('Opzione Struttura', Icons.business),
                items: [
                  const DropdownMenuItem(value: null, child: Text("Nessuna (Evento Libero)")),
                  ...approvedRequests.map((req) => DropdownMenuItem(
                    value: req.venueName,
                    child: Text(req.venueName),
                  )),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedVenueName = val;
                    if (val != null) {
                      // Se scelgo una struttura, aggiorno indirizzo e nome
                      final req = approvedRequests.firstWhere((r) => r.venueName == val);
                      _addressController.text = req.venueAddress;
                      _nameController.text = "Evento presso $val";
                      _geocodeAddress();
                    } else {
                      // Se scelgo nessuna, svuoto per inserimento manuale
                      _addressController.clear();
                      _nameController.clear();
                    }
                  });
                },
              ),
              
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saveEvent, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('PUBBLICA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }
}