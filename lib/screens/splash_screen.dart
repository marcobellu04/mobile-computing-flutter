import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/geo_event_logo.dart'; // Importa il widget del logo
import 'home.dart'; // Importa la tua home

// --- WIDGET SPLASH SCREEN CORRETTO ---
class SplashScreen extends StatefulWidget {
  final String currentUserEmail;
  const SplashScreen({super.key, required this.currentUserEmail});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Timer di 2 secondi per mostrare il logo all'avvio
    Timer(const Duration(seconds: 2), () {
      if (widget.currentUserEmail.isEmpty) {
        // Se non c'è l'email, vai al login tramite la rotta definita
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // Se l'utente è loggato, vai alla HomeScreen tramite la rotta definita
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GeoEventLogo(fontSize: 45), // Il tuo bellissimo logo viola
            SizedBox(height: 30),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}