import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/forecast_model.dart';
import '../providers/weather_provider.dart';
import '../utils/weather_icons.dart';

class HourlyForecastCard extends StatelessWidget {
  final HourlyForecastModel item;
  final WeatherProvider provider;
  final bool isFirst;

  const HourlyForecastCard({
    super.key,
    required this.item,
    required this.provider,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = isFirst ? 'Now' : DateFormat('h a').format(item.time);
    final iconData = WeatherIconsHelper.getIconData(
      item.condition,
      iconCode: item.iconCode,
    );

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isFirst
            ? Theme.of(context).colorScheme.primary.withOpacity(0.18)
            : (isDark ? const Color(0xFF1E2638) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFirst
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
          width: isFirst ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Time
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
              color: isFirst
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Weather Icon
          Icon(
            iconData,
            size: 28,
            color: WeatherIconsHelper.getConditionColor(item.condition),
          ),
          const SizedBox(height: 6),

          // Temperature
          Text(
            provider.formatTemperature(item.temperature),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),

          // Rain Probability (if > 0%)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop,
                size: 11,
                color: item.rainProbability > 30 ? const Color(0xFF29B6F6) : Colors.grey,
              ),
              const SizedBox(width: 2),
              Text(
                '${item.rainProbability}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: item.rainProbability > 30
                      ? const Color(0xFF29B6F6)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Wind Speed
          Text(
            provider.formatWindSpeed(item.windSpeed),
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
