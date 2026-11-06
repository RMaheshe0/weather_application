import 'package:flutter/material.dart';

class WeatherIconsHelper {
  /// Returns a clean Material 3 IconData for a weather condition or icon code
  static IconData getIconData(String condition, {String? iconCode, bool isNight = false}) {
    final lowerCond = condition.toLowerCase();
    final isNightTime = isNight || (iconCode != null && iconCode.endsWith('n'));

    if (lowerCond.contains('thunder') || lowerCond.contains('storm')) {
      return Icons.thunderstorm_rounded;
    }
    if (lowerCond.contains('drizzle')) {
      return Icons.grain_rounded;
    }
    if (lowerCond.contains('rain')) {
      if (lowerCond.contains('heavy') || lowerCond.contains('shower')) {
        return Icons.water_drop_rounded;
      }
      return Icons.water_drop_outlined;
    }
    if (lowerCond.contains('snow') || lowerCond.contains('blizzard') || lowerCond.contains('sleet')) {
      return Icons.ac_unit_rounded;
    }
    if (lowerCond.contains('mist') || lowerCond.contains('smoke') || lowerCond.contains('haze') || lowerCond.contains('dust') || lowerCond.contains('fog')) {
      return Icons.blur_on_rounded;
    }
    if (lowerCond.contains('clear')) {
      return isNightTime ? Icons.nightlight_round : Icons.wb_sunny_rounded;
    }
    if (lowerCond.contains('cloud')) {
      if (lowerCond.contains('few') || lowerCond.contains('scattered') || lowerCond.contains('partly')) {
        return isNightTime ? Icons.nights_stay_rounded : Icons.wb_cloudy_rounded;
      }
      return Icons.cloud_rounded;
    }

    // Default icon
    return isNightTime ? Icons.bedtime_rounded : Icons.wb_sunny_rounded;
  }

  /// Returns an appropriate color accent for the condition
  static Color getConditionColor(String condition, {bool isNight = false}) {
    final lowerCond = condition.toLowerCase();
    if (isNight) return const Color(0xFF90CAF9);

    if (lowerCond.contains('thunder')) return const Color(0xFFFFD54F);
    if (lowerCond.contains('rain') || lowerCond.contains('drizzle')) return const Color(0xFF64B5F6);
    if (lowerCond.contains('snow')) return const Color(0xFFE0F7FA);
    if (lowerCond.contains('fog') || lowerCond.contains('mist')) return const Color(0xFFB0BEC5);
    if (lowerCond.contains('cloud')) return const Color(0xFF90A4AE);
    return const Color(0xFFFFA726); // Sunny
  }
}
