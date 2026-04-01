import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'auth/login.dart';
import 'auth/register.dart';
import 'providers/likes_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/event_provider.dart';
import 'providers/venue_provider.dart';
import 'providers/message_provider.dart';
import 'screens/home.dart';
import 'screens/user_profile_page.dart';
import 'screens/map_screen.dart';

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
        ChangeNotifierProvider(
          create: (_) => EventProvider()..loadEvents(),
        ),
        ChangeNotifierProvider(
          create: (_) => VenueProvider()..loadVenues(),
        ),
        ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => LikesProvider()),
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
      
      // Forza l'app in modalità chiara
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

      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => HomeScreen(currentUserEmail: currentUserEmail),
        '/profile_edit': (context) => const UserProfilePage(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}