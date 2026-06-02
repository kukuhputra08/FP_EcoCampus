import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle heading1({
    Color color = const Color(0xFF0F172A), required int fontSize, required FontWeight fontWeight,
  }) {
    return GoogleFonts.ubuntu(
      fontSize: 32,
      height: 1.15,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }

  static TextStyle heading2({
    Color color = const Color(0xFF0F172A),
  }) {
    return GoogleFonts.ubuntu(
      fontSize: 26,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }

  static TextStyle title({
    Color color = const Color(0xFF0F172A),
  }) {
    return GoogleFonts.ubuntu(
      fontSize: 18,
      height: 1.35,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  static TextStyle body({
    Color color = const Color(0xFF475569), required int fontSize, required FontWeight fontWeight,
  }) {
    return GoogleFonts.ubuntu(
      fontSize: 15,
      height: 1.55,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle bodyMedium({
    Color color = const Color(0xFF475569),
  }) {
    return GoogleFonts.ubuntu(
      fontSize: 15,
      height: 1.5,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle button({
    Color color = Colors.white,
  }) {
    return GoogleFonts.ubuntu(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: 0.2,
    );
  }

  static TextStyle caption({
    Color color = const Color(0xFF64748B), required int fontSize, required FontWeight fontWeight,
  }) {
    return GoogleFonts.ubuntu(
      fontSize: 13,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle label({
    Color color = const Color(0xFF0F172A),
  }) {
    return GoogleFonts.ubuntu(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }
}