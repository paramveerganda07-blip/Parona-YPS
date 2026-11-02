// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class YPSColors {
  static const Color primaryMaroon = Color(0xFF800000); // Deep YPS Maroon
  static const Color backgroundLight = Color(0xFFF4F6F8); // Clean, airy background
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Pure white for cards
  static const Color textPrimary = Color(0xFF1A1A24); // Sharp, readable dark text
  static const Color textSecondary = Color(0xFF6B7280); // Professional grey for subtitles
  static const Color heritageGold = Color(0xFFD4AF37); // Classic gold accent
  static const Color alertRed = Color(0xFFE53935); // For "Happening Now"
}

class YPSTypography {
  static const TextStyle cinematicHeader = TextStyle(
    fontFamily: 'SF Pro Display',
    fontSize: 28, // Slightly refined for light mode
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: YPSColors.textPrimary,
  );
  
  static const TextStyle bodyElegant = TextStyle(
    fontFamily: 'SF Pro Text',
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: YPSColors.textSecondary,
  );
}