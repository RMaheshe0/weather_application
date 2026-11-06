import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';

class WeatherDetailsCard extends StatelessWidget {
  final WeatherModel weather;
  final WeatherProvider provider;

  const WeatherDetailsCard({
    super.key,
    required this.weather,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final sunriseStr = weather.sunrise.year > 1970 ? timeFormat.format(weather.sunrise) : '--:--';
    final sunsetStr = weather.sunset.year > 1970 ? timeFormat.format(weather.sunset) : '--:--';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: [
              _buildDetailTile(
                context,
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF29B6F6),
                title: 'Humidity',
                value: '${weather.humidity}%',
              ),
              _buildDetailTile(
                context,
                icon: Icons.air_rounded,
                iconColor: const Color(0xFF26A69A),
                title: 'Wind',
                value: '${provider.formatWindSpeed(weather.windSpeed)} • ${weather.windDirectionCardinal}',
              ),
              _buildDetailTile(
                context,
                icon: Icons.compress_rounded,
                iconColor: const Color(0xFFAB47BC),
                title: 'Pressure',
                value: '${weather.pressure} hPa',
              ),
              _buildDetailTile(
                context,
                icon: Icons.visibility_rounded,
                iconColor: const Color(0xFFFFA726),
                title: 'Visibility',
                value: '${weather.visibilityKm.toStringAsFixed(1)} km',
              ),
              _buildDetailTile(
                context,
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFFFB300),
                title: 'Sunrise',
                value: sunriseStr,
              ),
              _buildDetailTile(
                context,
                icon: Icons.nightlight_round,
                iconColor: const Color(0xFF5C6BC0),
                title: 'Sunset',
                value: sunsetStr,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
