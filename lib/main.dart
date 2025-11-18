import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/login.dart';
import 'auth/register.dart';
import 'screens/home.dart';
import 'providers/event_provider.dart';
import 'providers/venue_provider.dart';
import 'providers/message_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final messageProvider = MessageProvider();
  await messageProvider.loadMessages(); // Carica i messaggi da SharedPreferences

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => VenueProvider()),
        ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
        // Utilizza .value per riutilizzare l'istanza già caricata
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
  brightness: Brightness.dark,          // Imposta tema scuro globale
  scaffoldBackgroundColor: Colors.black,  // Sfondo nero per tutte le pagine scaffold
  primarySwatch: Colors.deepPurple,
  fontFamily: 'TusJùo', // esempio font personalizzato, da aggiungere Fonts
),

      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
