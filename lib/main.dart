import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_first_app/screens/venue_requests_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

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

class AppColors {
  static const Color geoPurple = Color.fromARGB(255, 54, 14, 95);
  static const Color geoYellow = Color(0xFFFFC107);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness:
          Brightness.dark,
    ),
  );

  await Firebase.initializeApp();

  final messageProvider = MessageProvider();
  await messageProvider.loadMessages();

  final prefs = await SharedPreferences.getInstance();
  final currentUserEmail =
      prefs.getString('user_email') ?? '';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              VenueProvider()..loadVenues(),
        ),
        ChangeNotifierProvider<MessageProvider>.value(
          value: messageProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => FilterProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ThemeProvider()..loadTheme(),
        ),
        ChangeNotifierProvider(
          create: (_) => LikesProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              EventProvider()..loadEvents(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              BookingProvider()..loadRequests(),
        ),
      ],
      child: MyApp(
        currentUserEmail: currentUserEmail,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String currentUserEmail;

  const MyApp({
    super.key,
    required this.currentUserEmail,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness:
            Brightness.dark,
        statusBarBrightness:
            Brightness.light,
        systemNavigationBarColor:
            Colors.white,
        systemNavigationBarIconBrightness:
            Brightness.dark,
      ),
      child: MaterialApp(
        title: 'GEOEVENT',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,

        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor:
              Colors.white,
          primarySwatch: Colors.amber,
          primaryColor:
              AppColors.geoYellow,
          fontFamily: 'Lato',

          appBarTheme: const AppBarTheme(
            systemOverlayStyle:
                SystemUiOverlayStyle(
              statusBarColor:
                  Colors.white,
              statusBarIconBrightness:
                  Brightness.dark,
              statusBarBrightness:
                  Brightness.light,
            ),
            backgroundColor:
                Colors.white,
            foregroundColor:
                Colors.black,
            elevation: 0,
            iconTheme:
                IconThemeData(
              color: Colors.black,
            ),
            titleTextStyle:
                TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),

          textTheme:
              const TextTheme(
            bodyMedium: TextStyle(
              color: Colors.black87,
            ),
            bodyLarge: TextStyle(
              color: Colors.black,
            ),
            titleLarge: TextStyle(
              fontWeight:
                  FontWeight.bold,
              color: Colors.black,
            ),
          ),

          elevatedButtonTheme:
              ElevatedButtonThemeData(
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.geoYellow,
              foregroundColor:
                  Colors.black,
              elevation: 0,
              textStyle:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                        12),
              ),
            ),
          ),
        ),

        home: SplashScreen(
          currentUserEmail:
              currentUserEmail,
        ),

        routes: {
          '/login': (context) =>
              const LoginScreen(),
          '/register': (context) =>
              const RegisterScreen(),
          '/home': (context) =>
              HomeScreen(
                currentUserEmail:
                    currentUserEmail,
              ),
          '/profile_edit':
              (context) =>
                  const UserProfilePage(),
          '/map': (context) =>
              const MapScreen(),
          '/venue_requests':
              (context) =>
                  VenueRequestsPage(
                    venueEmail:
                        currentUserEmail,
                  ),
        },
      ),
    );
  }
}

// ---------------- SPLASH SCREEN ----------------

class SplashScreen
    extends StatefulWidget {
  final String currentUserEmail;

  const SplashScreen({
    super.key,
    required this.currentUserEmail,
  });

  @override
  State<SplashScreen>
      createState() =>
          _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(
      const Duration(seconds: 2),
      () {
        if (widget
            .currentUserEmail
            .isEmpty) {
          Navigator
              .pushReplacementNamed(
            context,
            '/login',
          );
        } else {
          Navigator
              .pushReplacementNamed(
            context,
            '/home',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<
        SystemUiOverlayStyle>(
      value:
          const SystemUiOverlayStyle(
        statusBarColor:
            AppColors.geoPurple,
        statusBarIconBrightness:
            Brightness.light,
        statusBarBrightness:
            Brightness.dark,
        systemNavigationBarColor:
            AppColors.geoPurple,
        systemNavigationBarIconBrightness:
            Brightness.light,
      ),
      child: Scaffold(
        backgroundColor:
            AppColors.geoPurple,
        body: SafeArea(
          top: false,
          child: Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Image.asset(
                    'assets/splash_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(
                    height: 30),
                const SizedBox(
                  width: 38,
                  height: 38,
                  child:
                      CircularProgressIndicator(
                    color: AppColors
                        .geoYellow,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}