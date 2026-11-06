import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/city_model.dart';
import '../providers/weather_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/city_search_bar.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/weather_details_card.dart';
import '../widgets/hourly_forecast_card.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToHourly;
  final VoidCallback onNavigateToWeekly;

  const HomeScreen({
    super.key,
    required this.onNavigateToHourly,
    required this.onNavigateToWeekly,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final weather = provider.currentWeather;
        final isNight = weather?.isNight ?? false;
        final condition = weather?.condition ?? 'Clear';
        final gradient = AppTheme.getWeatherGradient(condition, isNight: isNight);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              weather?.cityName ?? 'SkyPulse Weather',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
            ),
            actions: [
              // Favorite Toggle Button
              if (weather != null)
                IconButton(
                  icon: Icon(
                    provider.isCitySaved(weather.cityName)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: Colors.white,
                  ),
                  tooltip: provider.isCitySaved(weather.cityName)
                      ? 'Saved in Favorites'
                      : 'Add to Favorites',
                  onPressed: () {
                    if (provider.isCitySaved(weather.cityName)) {
                      provider.removeCityFromFavorites(
                        CityModel(
                          name: weather.cityName,
                          country: weather.country,
                          latitude: weather.latitude,
                          longitude: weather.longitude,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${weather.cityName} removed from favorites'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      provider.addCityToFavorites(
                        CityModel(
                          name: weather.cityName,
                          country: weather.country,
                          latitude: weather.latitude,
                          longitude: weather.longitude,
                          currentTemp: weather.temperature,
                          condition: weather.condition,
                          iconCode: weather.iconCode,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${weather.cityName} added to favorites'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),

              // Refresh Button
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Refresh Weather',
                onPressed: provider.isLoading ? null : () => provider.refreshWeather(),
              ),

              // Settings Action
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(gradient: gradient),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: provider.refreshWeather,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Search Bar
                    CitySearchBar(provider: provider),
                    const SizedBox(height: 16),

                    // Loading State
                    if (provider.isLoading && weather == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )

                    // Error State
                    else if (provider.errorMessage != null && weather == null)
                      _buildErrorCard(context, provider)

                    // Loaded Weather Dashboard
                    else if (weather != null) ...[
                      // Hero Card
                      CurrentWeatherCard(
                        weather: weather,
                        provider: provider,
                      ),
                      const SizedBox(height: 20),

                      // Hourly Forecast Preview Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Hourly Forecast',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed: onNavigateToHourly,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withOpacity(0.9),
                            ),
                            child: const Row(
                              children: [
                                Text('See 24h', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                SizedBox(width: 2),
                                Icon(Icons.arrow_forward_ios_rounded, size: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Horizontal Hourly List
                      if (provider.hourlyForecast.isNotEmpty)
                        SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.hourlyForecast.length,
                            itemBuilder: (context, index) {
                              return HourlyForecastCard(
                                item: provider.hourlyForecast[index],
                                provider: provider,
                                isFirst: index == 0,
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Detailed Weather Grid
                      WeatherDetailsCard(
                        weather: weather,
                        provider: provider,
                      ),
                      const SizedBox(height: 20),

                      // Quick 7-Day Banner
                      InkWell(
                        onTap: onNavigateToWeekly,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '7-Day Extended Forecast',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Explore rain probabilities & daily temperatures',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorCard(BuildContext context, WeatherProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white38),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 54, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'Unable to Load Weather',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage ?? 'Please check network connection or verify city name.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => provider.refreshWeather(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
