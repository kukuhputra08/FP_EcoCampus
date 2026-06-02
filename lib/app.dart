import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/splash/splash_page.dart';

class EcoCampusApp extends StatelessWidget {
  const EcoCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoCampus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16A34A),
          primary: const Color(0xFF16A34A),
          secondary: const Color(0xFF14B8A6),
          background: const Color(0xFFF8FAF9),
        ),

        scaffoldBackgroundColor: const Color(0xFFF8FAF9),

        textTheme: GoogleFonts.ubuntuTextTheme(),

        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF8FAF9),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.ubuntu(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
          iconTheme: const IconThemeData(
            color: Color(0xFF0F172A),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: GoogleFonts.ubuntu(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFF16A34A),
              width: 1.5,
            ),
          ),
          hintStyle: GoogleFonts.ubuntu(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
          ),
        ),
      ),
      home: const SplashPage(),
    );
  }
}