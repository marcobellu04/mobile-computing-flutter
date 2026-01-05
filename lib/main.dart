import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/login.dart';
import 'auth/register.dart';
import 'screens/home.dart';
import 'providers/event_provider.dart';
import 'providers/venue_provider.dart';
import 'providers/message_provider.dart';
import 'screens/map_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final messageProvider = MessageProvider();
  await messageProvider.loadMessages(); // Carica i messaggi da SharedPreferences

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()..loadEvents()),
        ChangeNotifierProvider(create: (_) => VenueProvider()),
        ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GEOEVENT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,            // Tema scuro globale
        scaffoldBackgroundColor: Colors.black, // Sfondo nero scaffold
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Lato',                     // Imposta il font globale a Lato
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontWeight: FontWeight.normal),
          bodyLarge: TextStyle(fontWeight: FontWeight.normal),
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(fontWeight: FontWeight.bold),
          labelLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/map': (context) => const MapScreen(),

        // aggiungi altre rotte se serve
      },
    );
  }
}
