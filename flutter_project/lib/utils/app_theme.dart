import 'package:flutter/material.dart';

class AppTheme {
  // Material 3 Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E88E5),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      cardTheme: const CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  // Material 3 Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF64B5F6),
        brightness: Brightness.dark,
        surface: const Color(0xFF161B26),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F141C),
      cardTheme: const CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  /// Dynamic background gradients based on weather conditions
  /// Requirements:
  /// - Sunny: warm yellow and orange
  /// - Cloudy: grey and blue
  /// - Rainy: dark blue
  /// - Night: deep navy
  /// - Snowy: cool white and blue
  static LinearGradient getWeatherGradient(String condition, {bool isNight = false}) {
    if (isNight) {
      // Night: deep navy
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0B1325),
          Color(0xFF14213D),
          Color(0xFF1B2A4A),
        ],
      );
    }

    final lower = condition.toLowerCase();

    if (lower.contains('snow') || lower.contains('ice') || lower.contains('sleet')) {
      // Snowy: cool white and blue
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF7BA0C0),
          Color(0xFFB0CDE5),
          Color(0xFFE2EDF8),
        ],
      );
    }

    if (lower.contains('rain') || lower.contains('thunder') || lower.contains('drizzle')) {
      // Rainy: dark blue
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1A365D),
          Color(0xFF2A4365),
          Color(0xFF2C5282),
        ],
      );
    }

    if (lower.contains('cloud') || lower.contains('fog') || lower.contains('mist') || lower.contains('haze')) {
      // Cloudy: grey and blue
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4A5568),
          Color(0xFF718096),
          Color(0xFF90A4AE),
        ],
      );
    }

    // Sunny: warm yellow and orange
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFF7A00),
        Color(0xFFFF9E00),
        Color(0xFFFFC000),
      ],
    );
  }
}
