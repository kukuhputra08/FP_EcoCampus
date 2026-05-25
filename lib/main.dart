import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/homescreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar transparan, icon terang (cocok dengan header gelap)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Paksa orientasi portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const EcoCampusApp());
}

class EcoCampusApp extends StatelessWidget {
  const EcoCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoCampus',
      debugShowCheckedModeBanner: false,

      // ── Theme ──────────────────────────────────
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A6B4A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4FAF7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D4A30),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      // ── Route langsung ke HomeScreen ──────────
      home: const HomeScreen(),

      // ── Named Routes (siap diperluas nanti) ───
      routes: {
        '/home': (context) => const HomeScreen(),
        // TODO: tambahkan route lain di sini
        // '/report/create' : (context) => const CreateReportScreen(),
        // '/challenge'     : (context) => const ChallengeScreen(),
        // '/event'         : (context) => const EventScreen(),
        // '/profile'       : (context) => const ProfileScreen(),
        // '/login'         : (context) => const LoginScreen(),
      },
    );
  }
}