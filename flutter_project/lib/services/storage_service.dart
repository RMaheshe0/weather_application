import 'package:shared_preferences/shared_preferences.dart';
import '../models/city_model.dart';
import '../utils/constants.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Saved Favorite Cities
  List<CityModel> getSavedCities() {
    final raw = _prefs?.getString(AppConstants.prefKeySavedCities);
    if (raw == null || raw.isEmpty) {
      // Default sample cities on first launch
      return [
        CityModel(name: 'London', country: 'GB', latitude: 51.5074, longitude: -0.1278),
        CityModel(name: 'Tokyo', country: 'JP', latitude: 35.6762, longitude: 139.6503),
        CityModel(name: 'New York', country: 'US', latitude: 40.7128, longitude: -74.0060),
      ];
    }
    try {
      return CityModel.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveCities(List<CityModel> cities) async {
    final encoded = CityModel.encodeList(cities);
    return await _prefs?.setString(AppConstants.prefKeySavedCities, encoded) ?? false;
  }

  // Temperature Unit
  TemperatureUnit getTemperatureUnit() {
    final val = _prefs?.getString(AppConstants.prefKeyTempUnit);
    if (val == 'fahrenheit') return TemperatureUnit.fahrenheit;
    return TemperatureUnit.celsius;
  }

  Future<bool> setTemperatureUnit(TemperatureUnit unit) async {
    final val = unit == TemperatureUnit.fahrenheit ? 'fahrenheit' : 'celsius';
    return await _prefs?.setString(AppConstants.prefKeyTempUnit, val) ?? false;
  }

  // Wind Speed Unit
  WindSpeedUnit getWindSpeedUnit() {
    final val = _prefs?.getString(AppConstants.prefKeyWindUnit);
    if (val == 'ms') return WindSpeedUnit.ms;
    return WindSpeedUnit.kmh;
  }

  Future<bool> setWindSpeedUnit(WindSpeedUnit unit) async {
    final val = unit == WindSpeedUnit.ms ? 'ms' : 'kmh';
    return await _prefs?.setString(AppConstants.prefKeyWindUnit, val) ?? false;
  }

  // Theme Mode
  AppThemePreference getThemePreference() {
    final val = _prefs?.getString(AppConstants.prefKeyThemeMode);
    if (val == 'light') return AppThemePreference.light;
    if (val == 'dark') return AppThemePreference.dark;
    return AppThemePreference.system;
  }

  Future<bool> setThemePreference(AppThemePreference pref) async {
    String val = 'system';
    if (pref == AppThemePreference.light) val = 'light';
    if (pref == AppThemePreference.dark) val = 'dark';
    return await _prefs?.setString(AppConstants.prefKeyThemeMode, val) ?? false;
  }

  // OpenWeatherMap Custom API Key
  String? getApiKey() {
    return _prefs?.getString(AppConstants.prefKeyOwmApiKey);
  }

  Future<bool> setApiKey(String key) async {
    return await _prefs?.setString(AppConstants.prefKeyOwmApiKey, key.trim()) ?? false;
  }

  // Last active city
  String? getLastCity() {
    return _prefs?.getString(AppConstants.prefKeyLastCity);
  }

  Future<bool> setLastCity(String cityName) async {
    return await _prefs?.setString(AppConstants.prefKeyLastCity, cityName) ?? false;
  }
}
