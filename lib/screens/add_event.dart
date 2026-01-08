import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../providers/event_provider.dart';

class AddEventScreen extends StatefulWidget {
  final String ownerEmail;
  final String ownerName;    // nome proprietario
  final String ownerSurname; // cognome proprietario

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
  final TextEditingController _addressController = TextEditingController(); // indirizzo completo

  DateTime? _selectedDate;
  int _maxParticipants = 10;
  ListType _listType = ListType.open;
  String? _selectedVenueId;

  AgeRestrictionType _ageRestrictionType = AgeRestrictionType.none;
  int? _ageRestrictionValue;

  // immagine evento
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // per ora venue dummy, poi si può collegare alle venue reali
  final List<Map<String, String>> _venues = [
    {'id': 'v1', 'name': 'Struttura A'},
    {'id': 'v2', 'name': 'Struttura B'},
    {'id': 'v3', 'name': 'Struttura C'},
  ];

  Future<void> _pickImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _zoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Compila tutti i campi obbligatori e seleziona la data'),
        ),
      );
      return;
    }

    // se c'è filtro età ma manca valore valido
    if (_ageRestrictionType != AgeRestrictionType.none &&
        (_ageRestrictionValue == null || _ageRestrictionValue! <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un valore età valido')),
      );
      return;
    }

    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    final String? zone =
        _zoneController.text.trim().isEmpty ? null : _zoneController.text.trim();

    final String? fullAddress = _addressController.text.trim().isEmpty
        ? null
        : _addressController.text.trim();

    final newEvent = Event(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: _selectedDate!,
      zone: zone,
      // ora salvato davvero
      fullAddress: fullAddress,
      // usiamo i dati reali del proprietario che arrivano dal widget
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
      // se aggiungi imagePath a Event, passa qui: imagePath: _imageFile?.path,
    );

    eventProvider.addEvent(newEvent);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isPrivate = _listType == ListType.closed;

    final addressHelper = isPrivate
        ? 'Per eventi privati: visibile solo dopo approvazione/partecipazione.'
        : 'Per eventi pubblici: visibile ai partecipanti.';

    return Scaffold(
      appBar: AppBar(title: const Text('Aggiungi Evento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                            'Tocca per aggiungere un\'immagine evento',
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

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome Evento'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Inserisci nome evento'
                    : null,
              ),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Descrizione (opzionale)'),
                maxLines: 3,
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  ElevatedButton(
                    onPressed: _selectDate,
                    child: Text(
                      _selectedDate == null
                          ? 'Seleziona data'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_selectedDate == null)
                    const Text(
                      'Obbligatoria',
                      style: TextStyle(color: Colors.white70),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<ListType>(
                value: _listType,
                decoration:
                    const InputDecoration(labelText: 'Tipo lista partecipanti'),
                items: ListType.values
                    .map(
                      (lt) => DropdownMenuItem(
                        value: lt,
                        child: Text(
                          lt == ListType.open
                              ? 'Aperta'
                              : 'Chiusa (Privata)',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _listType = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 10),

              TextFormField(
                keyboardType: TextInputType.number,
                initialValue: _maxParticipants.toString(),
                decoration:
                    const InputDecoration(labelText: 'Max partecipanti'),
                validator: (val) {
                  final n = int.tryParse(val ?? '');
                  if (n == null || n <= 0) {
                    return 'Inserisci un numero valido';
                  }
                  return null;
                },
                onChanged: (val) {
                  final number = int.tryParse(val);
                  if (number != null) {
                    setState(() {
                      _maxParticipants = number;
                    });
                  }
                },
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _zoneController,
                decoration:
                    const InputDecoration(labelText: 'Zona (opzionale)'),
              ),

              const SizedBox(height: 10),

              // Indirizzo completo
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Indirizzo completo (opzionale)',
                  hintText: 'Es. Via Roma 10, 00100 Roma',
                ),
                keyboardType: TextInputType.streetAddress,
                maxLines: 2,
              ),
              const SizedBox(height: 6),
              Text(
                addressHelper,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _selectedVenueId,
                decoration: const InputDecoration(
                    labelText: 'Seleziona Struttura (opzionale)'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Nessuna struttura'),
                  ),
                  ..._venues
                      .map(
                        (v) => DropdownMenuItem(
                          value: v['id'],
                          child: Text(v['name']!),
                        ),
                      )
                      .toList(),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedVenueId = val;
                  });
                },
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<AgeRestrictionType>(
                value: _ageRestrictionType,
                decoration:
                    const InputDecoration(labelText: 'Restrizione età'),
                items: AgeRestrictionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type == AgeRestrictionType.none
                          ? 'Nessuna'
                          : type == AgeRestrictionType.under
                              ? 'Under (massimo)'
                              : 'Over (minimo)',
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _ageRestrictionType = val;
                      if (_ageRestrictionType == AgeRestrictionType.none) {
                        _ageRestrictionValue = null;
                      }
                    });
                  }
                },
              ),

              const SizedBox(height: 10),

              if (_ageRestrictionType != AgeRestrictionType.none)
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Valore età (es. 18)'),
                  validator: (val) {
                    final n = int.tryParse(val ?? '');
                    if (n == null || n <= 0) {
                      return 'Inserisci un numero valido';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    final number = int.tryParse(val);
                    setState(() {
                      _ageRestrictionValue = number;
                    });
                  },
                ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveEvent,
                child: const Text('Salva'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
