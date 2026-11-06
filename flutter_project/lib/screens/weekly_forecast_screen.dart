import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/daily_forecast_card.dart';

class WeeklyForecastScreen extends StatelessWidget {
  const WeeklyForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final weekly = provider.weeklyForecast;
        final weather = provider.currentWeather;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                const Text('7-Day Forecast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                if (weather != null)
                  Text(
                    weather.cityName,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
                  ),
              ],
            ),
          ),
          body: provider.isLoading && weekly.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: provider.refreshWeather,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // Overview Banner
                      Container(
                        padding: const EdgeInsets.all(18),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.85),
                              Theme.of(context).colorScheme.primary.withOpacity(0.65),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tap on any day below to expand and view wind speeds, UV index, and sunrise/sunset times.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (weekly.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No weekly forecast data available.')),
                        )
                      else
                        ...weekly.asMap().entries.map((entry) {
                          final index = entry.key;
                          final day = entry.value;
                          return DailyForecastCard(
                            day: day,
                            provider: provider,
                            initiallyExpanded: index == 0,
                          );
                        }),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
