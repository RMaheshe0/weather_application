import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../models/forecast_model.dart';
import '../models/city_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService;
  StorageService? _storageService;

  WeatherModel? _currentWeather;
  List<HourlyForecastModel> _hourlyForecast = [];
  List<DailyForecastModel> _weeklyForecast = [];
  List<CityModel> _savedCities = [];
  
  String _selectedCity = AppConstants.defaultCityName;
  bool _isLoading = false;
  String? _errorMessage;

  TemperatureUnit _tempUnit = TemperatureUnit.celsius;
  WindSpeedUnit _windUnit = WindSpeedUnit.kmh;
  AppThemePreference _themePreference = AppThemePreference.system;
  String? _customApiKey;

  WeatherProvider({
    WeatherService? weatherService,
    StorageService? storageService,
  })  : _weatherService = weatherService ?? WeatherService(),
        _storageService = storageService;

  // Getters
  WeatherModel? get currentWeather => _currentWeather;
  List<HourlyForecastModel> get hourlyForecast => _hourlyForecast;
  List<DailyForecastModel> get weeklyForecast => _weeklyForecast;
  List<CityModel> get savedCities => _savedCities;
  String get selectedCity => _selectedCity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TemperatureUnit get tempUnit => _tempUnit;
  WindSpeedUnit get windUnit => _windUnit;
  AppThemePreference get themePreference => _themePreference;
  String? get customApiKey => _customApiKey;
  bool get hasData => _currentWeather != null;

  /// Initialize provider with storage values
  Future<void> initialize() async {
    _storageService ??= await StorageService.getInstance();
    _tempUnit = _storageService!.getTemperatureUnit();
    _windUnit = _storageService!.getWindUnit();
    _themePreference = _storageService!.getThemePreference();
    _customApiKey = _storageService!.getApiKey();
    _savedCities = _storageService!.getSavedCities();
    
    if (_customApiKey != null) {
      _weatherService.customApiKey = _customApiKey;
    }

    final lastCity = _storageService!.getLastCity();
    final initialCity = (lastCity != null && lastCity.isNotEmpty)
        ? lastCity
        : (_savedCities.isNotEmpty ? _savedCities.first.name : AppConstants.defaultCityName);

    await fetchWeatherForCity(initialCity);
  }

  /// Fetch weather, hourly, and weekly forecast for a city name
  Future<void> fetchWeatherForCity(String cityName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final weather = await _weatherService.fetchCurrentWeather(cityName);
      final hourly = await _weatherService.fetchHourlyForecast(weather.latitude, weather.longitude);
      final weekly = await _weatherService.fetch7DayForecast(weather.latitude, weather.longitude);

      _currentWeather = weather;
      _hourlyForecast = hourly;
      _weeklyForecast = weekly;
      _selectedCity = weather.cityName;
      _errorMessage = null;

      // Update cached temp if this city is saved
      _updateSavedCityWeather(weather);

      // Remember last city
      _storageService?.setLastCity(weather.cityName);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch weather using device GPS position
  Future<void> fetchWeatherForCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        throw Exception('Unable to acquire current location.');
      }

      final resolvedName = await LocationService.getCityNameFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final weather = await _weatherService.fetchCurrentWeatherByCoords(
        position.latitude,
        position.longitude,
        resolvedName,
      );
      final hourly = await _weatherService.fetchHourlyForecast(weather.latitude, weather.longitude);
      final weekly = await _weatherService.fetch7DayForecast(weather.latitude, weather.longitude);

      _currentWeather = weather;
      _hourlyForecast = hourly;
      _weeklyForecast = weekly;
      _selectedCity = weather.cityName;
      _errorMessage = null;

      _updateSavedCityWeather(weather);
      _storageService?.setLastCity(weather.cityName);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh weather for currently selected city
  Future<void> refreshWeather() async {
    if (_currentWeather != null) {
      await fetchWeatherForCity(_currentWeather!.cityName);
    } else {
      await fetchWeatherForCity(_selectedCity);
    }
  }

  /// Search cities query
  Future<List<CityModel>> searchCities(String query) async {
    return await _weatherService.searchCities(query);
  }

  // ==========================================
  // Saved Cities Management
  // ==========================================

  bool isCitySaved(String cityName) {
    return _savedCities.any((c) => c.name.toLowerCase() == cityName.toLowerCase());
  }

  Future<void> addCityToFavorites(CityModel city) async {
    if (isCitySaved(city.name)) return; // Prevent duplicate cities

    // Populate current temperature if available
    CityModel toSave = city;
    if (_currentWeather != null && _currentWeather!.cityName.toLowerCase() == city.name.toLowerCase()) {
      toSave = city.copyWith(
        currentTemp: _currentWeather!.temperature,
        condition: _currentWeather!.condition,
        iconCode: _currentWeather!.iconCode,
      );
    }

    _savedCities.add(toSave);
    await _storageService?.saveCities(_savedCities);
    notifyListeners();
  }

  Future<void> removeCityFromFavorites(CityModel city) async {
    _savedCities.removeWhere((c) => c.name.toLowerCase() == city.name.toLowerCase());
    await _storageService?.saveCities(_savedCities);
    notifyListeners();
  }

  void _updateSavedCityWeather(WeatherModel weather) {
    bool changed = false;
    _savedCities = _savedCities.map((c) {
      if (c.name.toLowerCase() == weather.cityName.toLowerCase()) {
        changed = true;
        return c.copyWith(
          currentTemp: weather.temperature,
          condition: weather.condition,
          iconCode: weather.iconCode,
        );
      }
      return c;
    }).toList();

    if (changed) {
      _storageService?.saveCities(_savedCities);
    }
  }

  // ==========================================
  // Settings & Units
  // ==========================================

  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    _tempUnit = unit;
    await _storageService?.setTemperatureUnit(unit);
    notifyListeners();
  }

  Future<void> setWindSpeedUnit(WindSpeedUnit unit) async {
    _windUnit = unit;
    await _storageService?.setWindSpeedUnit(unit);
    notifyListeners();
  }

  Future<void> setThemePreference(AppThemePreference pref) async {
    _themePreference = pref;
    await _storageService?.setThemePreference(pref);
    notifyListeners();
  }

  Future<void> setCustomApiKey(String key) async {
    _customApiKey = key.trim();
    _weatherService.customApiKey = _customApiKey;
    await _storageService?.setApiKey(key.trim());
    notifyListeners();
    // Re-fetch with new API key
    await refreshWeather();
  }

  // ==========================================
  // Unit Conversion Helpers
  // ==========================================

  /// Formats temperature in Celsius or Fahrenheit
  String formatTemperature(double celsius) {
    if (_tempUnit == TemperatureUnit.fahrenheit) {
      final fahrenheit = (celsius * 9 / 5) + 32;
      return '${fahrenheit.round()}°F';
    }
    return '${celsius.round()}°C';
  }

  /// Formats wind speed in km/h or m/s
  String formatWindSpeed(double ms) {
    if (_windUnit == WindSpeedUnit.kmh) {
      final kmh = ms * 3.6;
      return '${kmh.toStringAsFixed(1)} km/h';
    }
    return '${ms.toStringAsFixed(1)} m/s';
  }
}
