import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'screens/home_screen.dart';
import 'screens/hourly_forecast_screen.dart';
import 'screens/weekly_forecast_screen.dart';
import 'screens/saved_cities_screen.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create provider and load saved settings, cities, and initial weather
  final weatherProvider = WeatherProvider();
  await weatherProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<WeatherProvider>.value(value: weatherProvider),
      ],
      child: const SkyPulseWeatherApp(),
    ),
  );
}

class SkyPulseWeatherApp extends StatelessWidget {
  const SkyPulseWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        ThemeMode themeMode = ThemeMode.system;
        if (provider.themePreference == AppThemePreference.light) {
          themeMode = ThemeMode.light;
        } else if (provider.themePreference == AppThemePreference.dark) {
          themeMode = ThemeMode.dark;
        }

        return MaterialApp(
          title: 'SkyPulse Weather',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const MainNavigationHolder(),
        );
      },
    );
  }
}

class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _currentIndex = 0;

  void _navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateToHourly: () => _navigateToIndex(1),
        onNavigateToWeekly: () => _navigateToIndex(2),
      ),
      const HourlyForecastScreen(),
      const WeeklyForecastScreen(),
      SavedCitiesScreen(
        onCityTapped: () => _navigateToIndex(0),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: WeatherBottomNavigationBar(
        currentIndex: _currentIndex,
        onDestinationSelected: _navigateToIndex,
      ),
    );
  }
}
