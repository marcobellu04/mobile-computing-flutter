import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/venue.dart';
import '../providers/venue_provider.dart';
import 'chat_page.dart';

class VenueDetailScreen extends StatefulWidget {
  final Venue venue;
  const VenueDetailScreen({super.key, required this.venue});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  String _me = '';

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _me = prefs.getString('user_email') ?? '';
      });
    }
  }

  bool _isOwner(Venue v) {
    if (_me.isEmpty) return false;
    final String owner = v.ownerEmail ?? '';
    return _me.trim().toLowerCase() == owner.trim().toLowerCase();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _confirmDelete(BuildContext context, VenueProvider provider, String venueId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Elimina Struttura"),
        content: const Text("Sei sicuro di voler eliminare definitivamente questa struttura?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annulla", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteVenue(venueId);
              Navigator.pop(ctx);
              Navigator.pop(context);
              _snack("Struttura eliminata correttamente");
            },
            child: const Text("Elimina", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _openInGoogleMaps(String address) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _snack('Impossibile aprire le mappe.');
    }
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.amber, size: 22),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venueProvider = context.watch<VenueProvider>();
    
    // Cerchiamo la versione aggiornata della struttura nel provider
    final current = venueProvider.venues.firstWhere(
      (v) => v.id == widget.venue.id,
      orElse: () => widget.venue,
    );

    final bool isOwner = _isOwner(current);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'venue-${current.id}',
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.45,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                    child: (current.imagePath != null && File(current.imagePath!).existsSync())
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                            child: Image.file(File(current.imagePath!), fit: BoxFit.cover),
                          )
                        : const Icon(Icons.storefront, size: 80, color: Colors.grey),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(current.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 25),
                      
                      GestureDetector(
                        onTap: current.address != null ? () => _openInGoogleMaps(current.address!) : null,
                        child: _buildInfoTile(
                          Icons.location_on_rounded, 
                          "Posizione", 
                          current.address ?? "Indirizzo non presente"
                        ),
                      ),
                      
                      if (current.phone != null && current.phone!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildInfoTile(Icons.phone_rounded, "Contatti", current.phone!),
                      ],

                      const Divider(height: 50),

                      _buildSectionTitle("Descrizione"),
                      Text(
                        current.description ?? "Nessuna descrizione fornita.", 
                        style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5)
                      ),

                      const Divider(height: 50),

                      _buildSectionTitle("Proprietario"),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber[100], 
                          child: Text(
                            (current.ownerName ?? "G")[0].toUpperCase(), 
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)
                          )
                        ),
                        // Mostriamo Nome e Cognome del proprietario
                        title: Text("${current.ownerName ?? 'Gestore'} ${current.ownerSurname ?? ''}", 
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(current.ownerEmail ?? "Email non disponibile"),
                      ),

                      const SizedBox(height: 120), 
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tasto Back
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                ),
              ),
            ),
          ),

          // Bottoni in fondo
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 15, 25, 25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: SizedBox(
                height: 55,
                child: isOwner 
                  ? ElevatedButton.icon(
                      onPressed: () => _confirmDelete(context, venueProvider, current.id),
                      icon: const Icon(Icons.delete_forever, color: Colors.white),
                      label: const Text("ELIMINA STRUTTURA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(
                          userEmail: _me,
                          venueEmail: current.ownerEmail ?? '',
                          venueName: "${current.ownerName} ${current.ownerSurname}",
                          role: "Gestore Struttura", // Ruolo dinamico
                        )));
                      },
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text("CONTATTA IL GESTORE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}