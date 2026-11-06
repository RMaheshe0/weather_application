import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/weather_provider.dart';
import '../utils/weather_icons.dart';
import '../widgets/weather_chart.dart';

class HourlyForecastScreen extends StatelessWidget {
  const HourlyForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final hourly = provider.hourlyForecast;
        final weather = provider.currentWeather;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                const Text('24-Hour Forecast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                if (weather != null)
                  Text(
                    weather.cityName,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
                  ),
              ],
            ),
          ),
          body: provider.isLoading && hourly.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: provider.refreshWeather,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // Interactive Weather Chart
                      WeatherChart(
                        hourlyData: hourly,
                        provider: provider,
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Hourly Breakdown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (hourly.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          child: const Text('No hourly forecast available.'),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: hourly.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = hourly[index];
                            final isFirst = index == 0;
                            final timeStr = isFirst ? 'Now' : DateFormat('h:mm a').format(item.time);
                            final iconData = WeatherIconsHelper.getIconData(item.condition, iconCode: item.iconCode);
                            final iconColor = WeatherIconsHelper.getConditionColor(item.condition);

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2638) : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isFirst
                                      ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                                      : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
                                  width: isFirst ? 1.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Time
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isFirst ? FontWeight.w700 : FontWeight.w600,
                                        color: isFirst
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),

                                  // Icon & Condition
                                  Icon(iconData, size: 24, color: iconColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.condition,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.water_drop, size: 11, color: Color(0xFF29B6F6)),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${item.rainProbability}%',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF29B6F6), fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(Icons.air, size: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                            const SizedBox(width: 2),
                                            Text(
                                              provider.formatWindSpeed(item.windSpeed),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Temperature
                                  Text(
                                    provider.formatTemperature(item.temperature),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
