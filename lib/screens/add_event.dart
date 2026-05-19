import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:geocoding/geocoding.dart';

import '../models/event.dart';
import '../providers/event_provider.dart';
import '../providers/booking_provider.dart'; 

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
  
  // NUOVI CONTROLLER PER PRECISIONE GEOLOCALIZZAZIONE
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _capController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final int _maxParticipants = 10;
  
  ListType _listType = ListType.open;
  final AgeRestrictionType _ageRestrictionType = AgeRestrictionType.none;
  int? _ageRestrictionValue;

  double? eventLat, eventLng;
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

  // Costruisce la stringa completa dell'indirizzo per evitare ambiguità
  String _buildFullAddressString() {
    if (widget.approvedVenueAddress != null || (_selectedVenueName != null && _selectedVenueName!.isNotEmpty)) {
      return _addressController.text.trim();
    }
    
    final via = _addressController.text.trim();
    final citta = _cityController.text.trim();
    final cap = _capController.text.trim();
    
    List<String> parts = [via];
    if (cap.isNotEmpty) parts.add(cap);
    if (citta.isNotEmpty) parts.add(citta);
    parts.add("Italia");
    
    return parts.join(", ");
  }

  Future<void> _geocodeAddress() async {
    final query = _buildFullAddressString();
    if (query.replaceAll(", Italia", "").trim().isEmpty) return;
    
    try {
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
      fullAddress: _buildFullAddressString(), // Salviamo l'indirizzo completo formattato bene
      ownerEmail: widget.ownerEmail,
      ownerName: widget.ownerName,
      ownerSurname: widget.ownerSurname,
      maxParticipants: _maxParticipants,
      listType: _listType,
      ageRestrictionType: _ageRestrictionType,
      ageRestrictionValue: _ageRestrictionValue,
      participants: [],
      pendingRequests: [],
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
    final bookingProvider = context.watch<BookingProvider>();
    final approvedRequests = bookingProvider.requests
        .where((r) => r.senderEmail == widget.ownerEmail && (r.status == 'approved' || r.status == 'accepted'))
        .toList();

    // Controlla se l'input manuale è bloccato (perché c'è una struttura associata)
    final bool isManualInputLocked = widget.approvedVenueAddress != null || (_selectedVenueName != null && _selectedVenueName!.isNotEmpty);

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
              
              // CAMPO 1: VIA E CIVICO
              TextFormField(
                controller: _addressController,
                readOnly: isManualInputLocked,
                decoration: _pillInput(
                  isManualInputLocked ? 'Indirizzo Struttura' : 'Via e Numero Civico *',
                  Icons.location_on,
                  suffix: isManualInputLocked ? const Icon(Icons.verified, color: Colors.green) : null,
                ),
                validator: (v) => v!.isEmpty ? 'L\'indirizzo è obbligatorio' : null,
              ),
              
              // SE L'INSERIMENTO È MANUALE, ABILITA I NUOVI CAMPI DETTAGLIATI
              if (!isManualInputLocked) ...[
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: _pillInput('Città *', Icons.location_city),
                        validator: (v) => v!.isEmpty ? 'Inserisci la città' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _capController,
                        keyboardType: TextInputType.number,
                        decoration: _pillInput('CAP', Icons.markunread_mailbox_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      if (_addressController.text.isNotEmpty && _cityController.text.isNotEmpty) {
                        await _geocodeAddress();
                        if (eventLat != null && eventLng != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Posizione verificata sulla mappa con successo!'), backgroundColor: Colors.green)
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Impossibile geolocalizzare, controlla i dati.'), backgroundColor: Colors.redAccent)
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Inserisci prima Via e Città per verificare.'))
                        );
                      }
                    },
                    icon: Icon(eventLat != null ? Icons.check_circle : Icons.gps_fixed, color: eventLat != null ? Colors.green : Colors.amber),
                    label: Text(eventLat != null ? 'Posizione Verificata' : 'Verifica Posizione sulla Mappa', style: TextStyle(color: eventLat != null ? Colors.green : Colors.amber, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],

              const SizedBox(height: 15),
              TextFormField(controller: _zoneController, decoration: _pillInput('Zona (es. Eur, Centro)', Icons.map_outlined), validator: (v) => v!.isEmpty ? 'Inserisci una zona' : null),
              const SizedBox(height: 15),
              DropdownButtonFormField<ListType>(initialValue: _listType, decoration: _pillInput('Tipo Lista', Icons.list), items: ListType.values.map((type) => DropdownMenuItem(value: type, child: Text(type == ListType.open ? 'Aperta' : 'Chiusa'))).toList(), onChanged: (v) => setState(() => _listType = v!)),
              
              const SizedBox(height: 15),
              
              DropdownButtonFormField<String?>(
                initialValue: _selectedVenueName,
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
                      final req = approvedRequests.firstWhere((r) => r.venueName == val);
                      _addressController.text = req.venueAddress;
                      _nameController.text = "Evento presso $val";
                      _geocodeAddress();
                    } else {
                      _addressController.clear();
                      _cityController.clear();
                      _capController.clear();
                      _nameController.clear();
                      eventLat = null;
                      eventLng = null;
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