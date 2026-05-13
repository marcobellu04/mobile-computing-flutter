import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // <--- AGGIUNTO per formattare la data
import '../models/message.dart'; 
import '../providers/booking_provider.dart';
import '../providers/message_provider.dart';

class VenueBookingForm extends StatefulWidget {
  final String currentUserEmail;
  final String venueEmail;
  final String venueName;
  final String venueAddress;

  const VenueBookingForm({
    super.key,
    required this.currentUserEmail,
    required this.venueEmail,
    required this.venueName,
    required this.venueAddress,
  });

  @override
  State<VenueBookingForm> createState() => _VenueBookingFormState();
}

class _VenueBookingFormState extends State<VenueBookingForm> {
  final _dateController = TextEditingController();
  final _peopleController = TextEditingController();
  final _msgController = TextEditingController();
  final _timeController = TextEditingController();

  // Funzione per selezionare la data tramite calendario
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Impedisce di selezionare date passate
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.amber),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  // Funzione per selezionare l'orario (semplificata a ora singola invece di range libero)
  Future<void> _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _timeController.text = pickedTime.format(context);
      });
    }
  }

  void _submitRequest() {
    if (_dateController.text.isEmpty || _peopleController.text.isEmpty || _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compila tutti i campi obbligatori")),
      );
      return;
    }

    final newRequest = VenueBookingRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderEmail: widget.currentUserEmail,
      venueEmail: widget.venueEmail,
      venueName: widget.venueName,
      venueAddress: widget.venueAddress,
      date: _dateController.text,
      timeRange: _timeController.text,
      peopleCount: int.tryParse(_peopleController.text) ?? 0,
      message: _msgController.text,
    );

    context.read<BookingProvider>().sendRequest(newRequest);

    final textNotif = "Richiesta di ospitalità per il ${newRequest.date} alle ore ${newRequest.timeRange}.";
    
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
            // Campo Data con selettore
            _buildField(
              "Data dell'evento", 
              _dateController, 
              Icons.calendar_today, 
              "Seleziona data",
              readOnly: true,
              onTap: _selectDate,
            ),
            const SizedBox(height: 15),
            
            // Campo Orario con selettore
            _buildField(
              "Orario inizio", 
              _timeController, 
              Icons.access_time, 
              "Seleziona orario",
              readOnly: true,
              onTap: _selectTime,
            ),
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

  // Helper aggiornato per gestire i click e il readOnly
  Widget _buildField(
    String label, 
    TextEditingController ctrl, 
    IconData icon, 
    String hint, 
    {TextInputType inputType = TextInputType.text, 
    int maxLines = 1, 
    bool readOnly = false, 
    VoidCallback? onTap}
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
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