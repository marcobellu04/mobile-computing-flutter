import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/login.dart';
import 'auth/register.dart';
import 'providers/likes_provider.dart';
import 'screens/home.dart';
import 'screens/user_profile_page.dart';
import 'providers/event_provider.dart';
import 'providers/venue_provider.dart';
import 'providers/message_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final messageProvider = MessageProvider();
  await messageProvider.loadMessages();

  final prefs = await SharedPreferences.getInstance();
  final currentUserEmail = prefs.getString('user_email') ?? '';

  runApp(
    MultiProvider(
      providers: [
        // carica eventi salvati
        ChangeNotifierProvider(
          create: (_) => EventProvider()..loadEvents(),
        ),
        // carica strutture salvate
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'GEOEVENT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Lato',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontWeight: FontWeight.normal),
          bodyLarge: TextStyle(fontWeight: FontWeight.normal),
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(fontWeight: FontWeight.bold),
          labelLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Lato',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontWeight: FontWeight.normal),
          bodyLarge: TextStyle(fontWeight: FontWeight.normal),
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(fontWeight: FontWeight.bold),
          labelLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => HomeScreen(currentUserEmail: currentUserEmail),
        '/profile_edit': (context) => const UserProfilePage(),
      },
    );
  }
}
