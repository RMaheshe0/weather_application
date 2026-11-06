import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/weather_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showApiKeyDialog(BuildContext context, WeatherProvider provider) {
    final controller = TextEditingController(text: provider.customApiKey ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('OpenWeatherMap API Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your 32-character API key from openweathermap.org. If left empty, SkyPulse automatically uses the built-in live meteorological service.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'e.g. 8f7e6d5c4b3a210...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                provider.setCustomApiKey(controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Key updated successfully.')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // UNITS SECTION
              _buildSectionHeader(context, 'UNITS OF MEASURE'),
              Container(
                decoration: _cardDecoration(context),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.thermostat_rounded, color: Colors.deepOrange),
                      title: const Text('Temperature Unit'),
                      subtitle: Text(
                        provider.tempUnit == TemperatureUnit.celsius ? 'Celsius (°C)' : 'Fahrenheit (°F)',
                      ),
                      trailing: SegmentedButton<TemperatureUnit>(
                        segments: const [
                          ButtonSegment(value: TemperatureUnit.celsius, label: Text('°C')),
                          ButtonSegment(value: TemperatureUnit.fahrenheit, label: Text('°F')),
                        ],
                        selected: {provider.tempUnit},
                        onSelectionChanged: (set) {
                          provider.setTemperatureUnit(set.first);
                        },
                      ),
                    ),
                    _buildDivider(context),
                    ListTile(
                      leading: const Icon(Icons.air_rounded, color: Colors.teal),
                      title: const Text('Wind Speed Unit'),
                      subtitle: Text(
                        provider.windUnit == WindSpeedUnit.kmh ? 'Kilometers per hour (km/h)' : 'Meters per second (m/s)',
                      ),
                      trailing: SegmentedButton<WindSpeedUnit>(
                        segments: const [
                          ButtonSegment(value: WindSpeedUnit.kmh, label: Text('km/h')),
                          ButtonSegment(value: WindSpeedUnit.ms, label: Text('m/s')),
                        ],
                        selected: {provider.windUnit},
                        onSelectionChanged: (set) {
                          provider.setWindSpeedUnit(set.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // APPEARANCE & THEME SECTION
              _buildSectionHeader(context, 'APPEARANCE & THEME'),
              Container(
                decoration: _cardDecoration(context),
                child: Column(
                  children: [
                    RadioListTile<AppThemePreference>(
                      title: const Text('System Default'),
                      subtitle: const Text('Follow Android device system theme'),
                      value: AppThemePreference.system,
                      groupValue: provider.themePreference,
                      secondary: const Icon(Icons.brightness_auto_rounded),
                      onChanged: (val) => provider.setThemePreference(val!),
                    ),
                    _buildDivider(context),
                    RadioListTile<AppThemePreference>(
                      title: const Text('Light Theme'),
                      value: AppThemePreference.light,
                      groupValue: provider.themePreference,
                      secondary: const Icon(Icons.light_mode_rounded, color: Colors.amber),
                      onChanged: (val) => provider.setThemePreference(val!),
                    ),
                    _buildDivider(context),
                    RadioListTile<AppThemePreference>(
                      title: const Text('Dark Theme'),
                      value: AppThemePreference.dark,
                      groupValue: provider.themePreference,
                      secondary: const Icon(Icons.dark_mode_rounded, color: Colors.indigoAccent),
                      onChanged: (val) => provider.setThemePreference(val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // DATA & PERMISSIONS SECTION
              _buildSectionHeader(context, 'DATA & PERMISSIONS'),
              Container(
                decoration: _cardDecoration(context),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.vpn_key_rounded, color: Colors.purple),
                      title: const Text('OpenWeatherMap API Key'),
                      subtitle: Text(
                        provider.customApiKey != null && provider.customApiKey!.isNotEmpty
                            ? 'Custom Key Active'
                            : 'Built-in Live Data Engine Active',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () => _showApiKeyDialog(context, provider),
                    ),
                    _buildDivider(context),
                    ListTile(
                      leading: const Icon(Icons.my_location_rounded, color: Colors.blue),
                      title: const Text('Location Permissions'),
                      subtitle: const Text('Open Android system app permission settings'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () async {
                        await Geolocator.openAppSettings();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // APPLICATION INFORMATION SECTION
              _buildSectionHeader(context, 'ABOUT SKYPULSE'),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.cloud_sync_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SkyPulse Weather', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            Text('Version 1.0.0 (Build 1)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'A complete, responsive Flutter Weather Forecast Android application engineered with Material 3, Provider architecture, live OpenWeatherMap & Open-Meteo APIs, and fl_chart graphical analytics.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E2638) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
    );
  }
}
