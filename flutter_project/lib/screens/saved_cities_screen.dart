import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/city_model.dart';
import '../providers/weather_provider.dart';
import '../utils/weather_icons.dart';

class SavedCitiesScreen extends StatelessWidget {
  final VoidCallback onCityTapped;

  const SavedCitiesScreen({
    super.key,
    required this.onCityTapped,
  });

  void _showAddCityDialog(BuildContext context, WeatherProvider provider) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Favorite City'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'City Name',
              hintText: 'e.g. Paris, Tokyo, Sydney',
              prefixIcon: Icon(Icons.location_city_rounded),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                _addCity(ctx, provider, val.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  _addCity(ctx, provider, textController.text.trim());
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addCity(BuildContext ctx, WeatherProvider provider, String cityName) async {
    Navigator.pop(ctx);
    if (provider.isCitySaved(cityName)) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('$cityName is already in your favorites!')),
      );
      return;
    }

    try {
      final results = await provider.searchCities(cityName);
      if (results.isNotEmpty) {
        final target = results.first;
        await provider.addCityToFavorites(target);
      } else {
        await provider.addCityToFavorites(
          CityModel(name: cityName, country: '', latitude: 0, longitude: 0),
        );
      }
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('$cityName added to favorites!')),
      );
    } catch (_) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Could not find $cityName')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final savedCities = provider.savedCities;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Saved Cities', style: TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add City',
                onPressed: () => _showAddCityDialog(context, provider),
              ),
            ],
          ),
          body: savedCities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_outline_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Saved Cities Yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your favorite cities to quickly check their weather.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => _showAddCityDialog(context, provider),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add a City'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: savedCities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final city = savedCities[index];
                    final isSelected = provider.selectedCity.toLowerCase() == city.name.toLowerCase();
                    final iconData = city.condition != null
                        ? WeatherIconsHelper.getIconData(city.condition!, iconCode: city.iconCode)
                        : Icons.wb_sunny_rounded;

                    return Dismissible(
                      key: Key('city_${city.name}_${city.country}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
                      ),
                      onDismissed: (_) {
                        provider.removeCityFromFavorites(city);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${city.name} removed from favorites'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () => provider.addCityToFavorites(city),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2638) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            city.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            city.country.isNotEmpty ? city.country : (city.condition ?? 'Tap to view'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (city.currentTemp != null)
                                Text(
                                  provider.formatTemperature(city.currentTemp!),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                color: Colors.grey,
                                splashRadius: 18,
                                onPressed: () {
                                  provider.removeCityFromFavorites(city);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            provider.fetchWeatherForCity(city.name);
                            onCityTapped();
                          },
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddCityDialog(context, provider),
            tooltip: 'Add City',
            child: const Icon(Icons.add_location_alt_rounded),
          ),
        );
      },
    );
  }
}
