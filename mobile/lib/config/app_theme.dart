import 'package:flutter/material.dart';

/// Central design tokens — Authentic Ludo King luxury gaming aesthetic.
class AppColors {
  AppColors._();

  // Rich gaming background & surface colors
  static const Color background = Color(0xFF0F1E36); // Deep Royal Navy Table
  static const Color backgroundDark = Color(0xFF070E1B); // Ultra dark navy
  static const Color surface = Color(0xFF1B2A4A); // Beveled Slate Card
  static const Color surfaceLight = Color(0xFF26395F); // Highlighted card
  static const Color ink = Color(0xFFFFFFFF); // Crisp White text
  static const Color inkMuted = Color(0xFFA0B2D6); // Cool blue-grey text
  
  // Metallic Accents
  static const Color gold = Color(0xFFFFD700); // 24k Gold
  static const Color accent = Color(0xFFFFD700); // Accent Gold alias
  static const Color goldLight = Color(0xFFFFF0A0); // Bright gold highlight
  static const Color goldDark = Color(0xFFB8860B); // Deep bronze shadow
  static const Color coinGold = Color(0xFFFFA502); // Warm arcade coin
  static const Color gemRuby = Color(0xFFFF4757); // Gem ruby red

  /// Authentic Ludo King 4-Player Palette:
  /// Seat 0: Red (Top-Left)
  /// Seat 1: Green (Top-Right)
  /// Seat 2: Yellow (Bottom-Right)
  /// Seat 3: Blue (Bottom-Left)
  static const List<Color> playerColors = [
    Color(0xFFE52521), // Seat 0: Crimson Red
    Color(0xFF00A651), // Seat 1: Emerald Green
    Color(0xFFFFB800), // Seat 2: Golden Yellow
    Color(0xFF0072CE), // Seat 3: Royal Blue
  ];

  static const List<Color> playerColorsLight = [
    Color(0xFFFF6B6B),
    Color(0xFF2ED573),
    Color(0xFFFFDF78),
    Color(0xFF54A0FF),
  ];

  static const List<Color> playerColorsDark = [
    Color(0xFF9E0B0F),
    Color(0xFF005C2B),
    Color(0xFFB87800),
    Color(0xFF00448E),
  ];

  static const List<String> playerNames = [
    'Red',
    'Green',
    'Yellow',
    'Blue',
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Nunito',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        surface: AppColors.surface,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontFamily: 'Fredoka',
          color: AppColors.goldLight,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          shadows: [
            const Shadow(
              color: Colors.black54,
              offset: Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontFamily: 'Fredoka',
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontFamily: 'Fredoka',
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontFamily: 'Fredoka',
          color: AppColors.ink,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: AppColors.ink),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.goldLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: const Color(0xFF2D1B00),
          elevation: 6,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.goldLight, width: 2),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
