class AppConstants {
  // OpenWeatherMap API Base URLs
  static const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String geoBaseUrl = 'https://api.openweathermap.org/geo/1.0';
  
  // Default OpenWeatherMap API Key placeholder or configurable via Settings/Environment
  // Users can easily set their personal key in Settings or through --dart-define=OWM_KEY=xxx
  static const String defaultOwmApiKey = String.fromEnvironment('OWM_KEY', defaultValue: 'YOUR_OPENWEATHERMAP_API_KEY');

  // Open-Meteo High-Reliability Fallback Base URLs (No API key needed, open-access)
  // This guarantees the app works out-of-the-box on any device even without an OWM key!
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';
  static const String openMeteoGeocodingUrl = 'https://geocoding-api.open-meteo.com/v1';

  // SharedPreferences Keys
  static const String prefKeySavedCities = 'skypulse_saved_cities';
  static const String prefKeyTempUnit = 'skypulse_temp_unit'; // 'celsius' or 'fahrenheit'
  static const String prefKeyWindUnit = 'skypulse_wind_unit'; // 'kmh' or 'ms'
  static const String prefKeyThemeMode = 'skypulse_theme_mode'; // 'system', 'light', 'dark'
  static const String prefKeyOwmApiKey = 'skypulse_owm_api_key';
  static const String prefKeyLastCity = 'skypulse_last_city';

  // Default initial cities
  static const String defaultCityName = 'London';
  static const double defaultLat = 51.5074;
  static const double defaultLon = -0.1278;
}

enum TemperatureUnit { celsius, fahrenheit }
enum WindSpeedUnit { kmh, ms }
enum AppThemePreference { system, light, dark }
