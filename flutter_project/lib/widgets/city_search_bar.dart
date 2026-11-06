import 'dart:async';
import 'package:flutter/material.dart';
import '../models/city_model.dart';
import '../providers/weather_provider.dart';

class CitySearchBar extends StatefulWidget {
  final WeatherProvider provider;
  final ValueChanged<String>? onCitySelected;

  const CitySearchBar({
    super.key,
    required this.provider,
    this.onCitySelected,
  });

  @override
  State<CitySearchBar> createState() => _CitySearchBarState();
}

class _CitySearchBarState extends State<CitySearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<CityModel> _suggestions = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      try {
        final results = await widget.provider.searchCities(query.trim());
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  void _selectCity(String cityName) {
    _controller.clear();
    _focusNode.unfocus();
    setState(() => _suggestions = []);
    widget.provider.fetchWeatherForCity(cityName);
    widget.onCitySelected?.call(cityName);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Input Container
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2638) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onQueryChanged,
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      _selectCity(val.trim());
                    }
                  },
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search city or country...',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),

              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  splashRadius: 16,
                  onPressed: () {
                    _controller.clear();
                    setState(() => _suggestions = []);
                  },
                ),

              // GPS Button
              IconButton(
                icon: const Icon(Icons.my_location_rounded, size: 20),
                tooltip: 'Current GPS Location',
                color: Theme.of(context).colorScheme.primary,
                splashRadius: 20,
                onPressed: () {
                  _focusNode.unfocus();
                  widget.provider.fetchWeatherForCurrentLocation();
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        // Suggestions Dropdown
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2638) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
              ),
              itemBuilder: (context, index) {
                final city = _suggestions[index];
                final stateCountry = [
                  if (city.state != null && city.state!.isNotEmpty) city.state,
                  if (city.country.isNotEmpty) city.country,
                ].join(', ');

                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_city_rounded, size: 20),
                  title: Text(
                    city.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: stateCountry.isNotEmpty
                      ? Text(stateCountry, style: const TextStyle(fontSize: 11))
                      : null,
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                  onTap: () => _selectCity(city.name),
                );
              },
            ),
          ),
      ],
    );
  }
}
