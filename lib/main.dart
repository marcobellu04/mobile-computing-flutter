import 'package:flutter/material.dart';
import 'package:my_first_app/screens/venue_requests_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'auth/login.dart';
import 'auth/register.dart';
import 'providers/booking_provider.dart';
import 'providers/likes_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/event_provider.dart';
import 'providers/venue_provider.dart';
import 'providers/message_provider.dart';
import 'screens/home.dart';
import 'screens/user_profile_page.dart';
import 'screens/map_screen.dart';
import 'widgets/geo_event_logo.dart'; // Import del logo

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final messageProvider = MessageProvider();
  await messageProvider.loadMessages();

  final prefs = await SharedPreferences.getInstance();
  final currentUserEmail = prefs.getString('user_email') ?? '';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VenueProvider()..loadVenues()),
        ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => LikesProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()..loadEvents()), 
        ChangeNotifierProvider(create: (_) => BookingProvider()..loadRequests()), 
      ],
      child: MyApp(currentUserEmail: currentUserEmail),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String currentUserEmail;

  const MyApp({super.key, required this.currentUserEmail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GEOEVENT',
      debugShowCheckedModeBanner: false,
      
      themeMode: ThemeMode.light, 
      
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.amber,
        primaryColor: Colors.amber,
        fontFamily: 'Lato',
        
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),

        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          bodyLarge: TextStyle(color: Colors.black),
          titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      // L'app parte dallo Splash Screen integrato sotto
      home: SplashScreen(currentUserEmail: currentUserEmail),
      
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => HomeScreen(currentUserEmail: currentUserEmail),
        '/profile_edit': (context) => const UserProfilePage(),
        '/map': (context) => const MapScreen(),
        '/venue_requests': (context) => VenueRequestsPage(venueEmail: currentUserEmail), 
      },
    );
  }
}

// --- CLASSE SPLASH SCREEN ADATTATA SENZA CONFLITTI DI SISTEMA ---
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
    Timer(const Duration(seconds: 2), () {
      if (widget.currentUserEmail.isEmpty) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Manteniamo lo Scaffold pulito impostando direttamente il viola esatto del pannello
      backgroundColor: const Color(0xFF320064),
      body: SafeArea(
        top: false, // Impedisce la creazione di bande nere o vuote nella parte alta dello schermo
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Box con il tuo logo centrato
              SizedBox(
                width: 280,
                height: 280,
                child: Image.asset(
                  'assets/app_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              // Caricamento discreto sotto il logo (colore giallo coordinato)
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Color(0xFFFFC107),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Initializing...",
                style: TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 14,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}