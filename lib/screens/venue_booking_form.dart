import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart'; 
import '../providers/booking_provider.dart';
import '../providers/message_provider.dart';

class VenueBookingForm extends StatefulWidget {
  final String currentUserEmail;
  final String venueEmail;
  final String venueName;
  final String venueAddress; // <--- AGGIUNTO: Riceviamo l'indirizzo dal dettaglio

  const VenueBookingForm({
    super.key,
    required this.currentUserEmail,
    required this.venueEmail,
    required this.venueName,
    required this.venueAddress, // <--- AGGIUNTO
  });

  @override
  State<VenueBookingForm> createState() => _VenueBookingFormState();
}

class _VenueBookingFormState extends State<VenueBookingForm> {
  final _dateController = TextEditingController();
  final _peopleController = TextEditingController();
  final _msgController = TextEditingController();
  final _timeController = TextEditingController();

  void _submitRequest() {
    if (_dateController.text.isEmpty || _peopleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compila i campi obbligatori")),
      );
      return;
    }

    // 1. Creazione della richiesta (Ora con venueAddress)
    final newRequest = VenueBookingRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderEmail: widget.currentUserEmail,
      venueEmail: widget.venueEmail,
      venueName: widget.venueName,
      venueAddress: widget.venueAddress, // <--- ORA LA RIGA 38 È CORRETTA
      date: _dateController.text,
      timeRange: _timeController.text,
      peopleCount: int.tryParse(_peopleController.text) ?? 0,
      message: _msgController.text,
    );

    // Salva nel BookingProvider
    context.read<BookingProvider>().sendRequest(newRequest);

    // 2. Notifica in Chat
    final textNotif = "Richiesta di ospitalità per il ${newRequest.date}. Controlla le tue richieste!";
    
    final messageObj = Message(
      senderEmail: widget.currentUserEmail,
      receiverEmail: widget.venueEmail,
      senderName: widget.currentUserEmail.split('@')[0], 
      receiverName: widget.venueName,
      text: textNotif,
      timestamp: DateTime.now(),
      isRead: false,
    );

    context.read<MessageProvider>().sendMessage(messageObj);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Richiesta inviata con successo!")),
    );
  }

  // ... Resto del widget (build e _buildField) rimane uguale ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Richiedi a ${widget.venueName}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildField("Data dell'evento", _dateController, Icons.calendar_today, "Es: 25/05/2026"),
            const SizedBox(height: 15),
            _buildField("Fascia oraria", _timeController, Icons.access_time, "Es: 18:00 - 23:00"),
            const SizedBox(height: 15),
            _buildField("Numero persone previste", _peopleController, Icons.group, "Es: 50", inputType: TextInputType.number),
            const SizedBox(height: 15),
            _buildField("Messaggio per il gestore", _msgController, Icons.message, "Racconta brevemente il tuo evento...", maxLines: 4),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: const Text(
                  "INVIA RICHIESTA", 
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, String hint, {TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.amber),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), 
          borderSide: const BorderSide(color: Colors.amber, width: 2)
        ),
      ),
    );
  }
}