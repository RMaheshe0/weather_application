import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../models/forecast_model.dart';
import '../models/city_model.dart';
import '../utils/constants.dart';

class WeatherService {
  final http.Client client;
  String? customApiKey;

  WeatherService({http.Client? client, this.customApiKey})
      : client = client ?? http.Client();

  String get _apiKey {
    if (customApiKey != null && customApiKey!.isNotEmpty && customApiKey != 'YOUR_OPENWEATHERMAP_API_KEY') {
      return customApiKey!;
    }
    return AppConstants.defaultOwmApiKey;
  }

  bool get _hasValidOwmKey =>
      _apiKey.isNotEmpty && _apiKey != 'YOUR_OPENWEATHERMAP_API_KEY';

  // ==========================================
  // Current Weather
  // ==========================================

  Future<WeatherModel> fetchCurrentWeather(String cityName) async {
    try {
      if (_hasValidOwmKey) {
        final url = Uri.parse(
          '${AppConstants.openWeatherBaseUrl}/weather?q=${Uri.encodeComponent(cityName)}&appid=$_apiKey&units=metric',
        );
        final response = await client.get(url).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return WeatherModel.fromOpenWeatherMapJson(data);
        } else if (response.statusCode == 404) {
          throw Exception('City "$cityName" not found. Please verify the spelling.');
        } else if (response.statusCode == 401) {
          // Fallback to Open-Meteo if key is invalid
          return await _fetchCurrentWeatherFromOpenMeteoByCity(cityName);
        } else {
          throw Exception('Weather service error (${response.statusCode}): ${response.reasonPhrase}');
        }
      } else {
        // Direct reliable live fallback via Open-Meteo
        return await _fetchCurrentWeatherFromOpenMeteoByCity(cityName);
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to load weather: $e');
    }
  }

  Future<WeatherModel> fetchCurrentWeatherByCoords(double lat, double lon, [String? fallbackCityName]) async {
    try {
      if (_hasValidOwmKey) {
        final url = Uri.parse(
          '${AppConstants.openWeatherBaseUrl}/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
        );
        final response = await client.get(url).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return WeatherModel.fromOpenWeatherMapJson(data);
        }
      }
      return await _fetchCurrentWeatherFromOpenMeteo(lat, lon, fallbackCityName);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to load weather for coordinates: $e');
    }
  }

  // ==========================================
  // Hourly Forecast (Next 24 Hours)
  // ==========================================

  Future<List<HourlyForecastModel>> fetchHourlyForecast(double lat, double lon) async {
    try {
      if (_hasValidOwmKey) {
        final url = Uri.parse(
          '${AppConstants.openWeatherBaseUrl}/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
        );
        final response = await client.get(url).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final list = (data['list'] as List<dynamic>?) ?? [];
          // Returns up to the next 8 items (3h each = 24 hours)
          return list.take(8).map((item) => HourlyForecastModel.fromOpenWeatherMapJson(item as Map<String, dynamic>)).toList();
        }
      }
      return await _fetchHourlyFromOpenMeteo(lat, lon);
    } catch (_) {
      // Fallback to Open-Meteo
      return await _fetchHourlyFromOpenMeteo(lat, lon);
    }
  }

  // ==========================================
  // 7-Day Daily Forecast
  // ==========================================

  Future<List<DailyForecastModel>> fetch7DayForecast(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '${AppConstants.openMeteoBaseUrl}/forecast?latitude=$lat&longitude=$lon&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,uv_index_max,sunrise,sunset&timezone=auto',
      );
      final response = await client.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final daily = data['daily'] as Map<String, dynamic>? ?? {};
        final times = (daily['time'] as List<dynamic>?) ?? [];
        final weatherCodes = (daily['weather_code'] as List<dynamic>?) ?? [];
        final maxTemps = (daily['temperature_2m_max'] as List<dynamic>?) ?? [];
        final minTemps = (daily['temperature_2m_min'] as List<dynamic>?) ?? [];
        final rainProbs = (daily['precipitation_probability_max'] as List<dynamic>?) ?? [];
        final windSpeeds = (daily['wind_speed_10m_max'] as List<dynamic>?) ?? [];
        final uvIndices = (daily['uv_index_max'] as List<dynamic>?) ?? [];
        final sunrises = (daily['sunrise'] as List<dynamic>?) ?? [];
        final sunsets = (daily['sunset'] as List<dynamic>?) ?? [];

        final List<DailyForecastModel> days = [];
        const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        for (int i = 0; i < times.length && i < 7; i++) {
          final dateStr = times[i] as String;
          final date = DateTime.parse(dateStr);
          final wCode = (weatherCodes.length > i ? (weatherCodes[i] as num).toInt() : 0);
          final parsedCondition = _mapWmoCodeToCondition(wCode);

          days.add(DailyForecastModel(
            date: date,
            dayName: i == 0 ? 'Today' : (i == 1 ? 'Tomorrow' : weekdayNames[date.weekday - 1]),
            tempMin: (minTemps.length > i ? (minTemps[i] as num).toDouble() : 15.0),
            tempMax: (maxTemps.length > i ? (maxTemps[i] as num).toDouble() : 24.0),
            tempDay: ((minTemps.length > i ? (minTemps[i] as num).toDouble() : 15.0) + (maxTemps.length > i ? (maxTemps[i] as num).toDouble() : 24.0)) / 2,
            condition: parsedCondition['condition']!,
            description: parsedCondition['description']!,
            iconCode: parsedCondition['iconCode']!,
            rainProbability: (rainProbs.length > i ? (rainProbs[i] as num?)?.round() ?? 0 : 0),
            humidity: 65,
            windSpeed: (windSpeeds.length > i ? (windSpeeds[i] as num).toDouble() / 3.6 : 3.5),
            uvIndex: (uvIndices.length > i ? (uvIndices[i] as num?)?.round() ?? 5 : 5),
            sunrise: sunrises.length > i ? DateTime.tryParse(sunrises[i]) : null,
            sunset: sunsets.length > i ? DateTime.tryParse(sunsets[i]) : null,
          ));
        }
        return days;
      }
      throw Exception('Failed to load 7-day forecast.');
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      throw Exception('Could not fetch 7-day forecast: $e');
    }
  }

  // ==========================================
  // City Search
  // ==========================================

  Future<List<CityModel>> searchCities(String query) async {
    final clean = query.trim();
    if (clean.length < 2) return [];

    try {
      if (_hasValidOwmKey) {
        final url = Uri.parse(
          '${AppConstants.geoBaseUrl}/direct?q=${Uri.encodeComponent(clean)}&limit=8&appid=$_apiKey',
        );
        final response = await client.get(url).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final list = jsonDecode(response.body) as List<dynamic>;
          return list.map((item) => CityModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }

      // High-speed Open-Meteo geocoding fallback
      final fallbackUrl = Uri.parse(
        '${AppConstants.openMeteoGeocodingUrl}/search?name=${Uri.encodeComponent(clean)}&count=8&language=en&format=json',
      );
      final fbResponse = await client.get(fallbackUrl).timeout(const Duration(seconds: 8));

      if (fbResponse.statusCode == 200) {
        final data = jsonDecode(fbResponse.body) as Map<String, dynamic>;
        final results = (data['results'] as List<dynamic>?) ?? [];
        return results.map((item) {
          final m = item as Map<String, dynamic>;
          return CityModel(
            name: (m['name'] as String?) ?? clean,
            country: (m['country_code'] as String?)?.toUpperCase() ?? (m['country'] as String?) ?? '',
            state: m['admin1'] as String?,
            latitude: (m['latitude'] as num).toDouble(),
            longitude: (m['longitude'] as num).toDouble(),
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ==========================================
  // Private Helpers for Open-Meteo Integration
  // ==========================================

  Future<WeatherModel> _fetchCurrentWeatherFromOpenMeteoByCity(String cityName) async {
    final search = await searchCities(cityName);
    if (search.isEmpty) {
      throw Exception('City "$cityName" not found. Please check spelling.');
    }
    final target = search.first;
    return await _fetchCurrentWeatherFromOpenMeteo(target.latitude, target.longitude, target.name, target.country);
  }

  Future<WeatherModel> _fetchCurrentWeatherFromOpenMeteo(double lat, double lon, [String? cityName, String? country]) async {
    final url = Uri.parse(
      '${AppConstants.openMeteoBaseUrl}/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max&timezone=auto',
    );
    final response = await client.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Could not fetch weather data from live service.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>? ?? {};
    final daily = data['daily'] as Map<String, dynamic>? ?? {};

    final wCode = (current['weather_code'] as num?)?.toInt() ?? 0;
    final isDay = (current['is_day'] as num?)?.toInt() == 1;
    final parsed = _mapWmoCodeToCondition(wCode, isDay: isDay);

    final maxTemps = (daily['temperature_2m_max'] as List<dynamic>?) ?? [];
    final minTemps = (daily['temperature_2m_min'] as List<dynamic>?) ?? [];
    final sunrises = (daily['sunrise'] as List<dynamic>?) ?? [];
    final sunsets = (daily['sunset'] as List<dynamic>?) ?? [];
    final uvList = (daily['uv_index_max'] as List<dynamic>?) ?? [];

    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 20.0;
    final feels = (current['apparent_temperature'] as num?)?.toDouble() ?? temp;
    final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 50;
    final windKmH = (current['wind_speed_10m'] as num?)?.toDouble() ?? 10.0;
    final windMS = windKmH / 3.6; // convert to m/s standard
    final windDeg = (current['wind_direction_10m'] as num?)?.toInt() ?? 0;
    final pressure = (current['surface_pressure'] as num?)?.round() ?? 1013;

    return WeatherModel(
      cityName: cityName ?? 'Local Area',
      country: country ?? '',
      latitude: lat,
      longitude: lon,
      temperature: temp,
      feelsLike: feels,
      tempMin: minTemps.isNotEmpty ? (minTemps[0] as num).toDouble() : temp - 3,
      tempMax: maxTemps.isNotEmpty ? (maxTemps[0] as num).toDouble() : temp + 4,
      humidity: humidity,
      windSpeed: windMS,
      windDegree: windDeg,
      pressure: pressure,
      visibilityKm: 10.0,
      condition: parsed['condition']!,
      description: parsed['description']!,
      iconCode: parsed['iconCode']!,
      dateTime: DateTime.now(),
      sunrise: sunrises.isNotEmpty ? DateTime.tryParse(sunrises[0]) ?? DateTime.now() : DateTime.now(),
      sunset: sunsets.isNotEmpty ? DateTime.tryParse(sunsets[0]) ?? DateTime.now() : DateTime.now(),
      uvIndex: uvList.isNotEmpty ? (uvList[0] as num?)?.round() ?? 5 : 5,
    );
  }

  Future<List<HourlyForecastModel>> _fetchHourlyFromOpenMeteo(double lat, double lon) async {
    final url = Uri.parse(
      '${AppConstants.openMeteoBaseUrl}/forecast?latitude=$lat&longitude=$lon&hourly=temperature_2m,apparent_temperature,precipitation_probability,weather_code,wind_speed_10m,relative_humidity_2m&forecast_hours=24&timezone=auto',
    );
    final response = await client.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final hourly = data['hourly'] as Map<String, dynamic>? ?? {};
    final times = (hourly['time'] as List<dynamic>?) ?? [];
    final temps = (hourly['temperature_2m'] as List<dynamic>?) ?? [];
    final feels = (hourly['apparent_temperature'] as List<dynamic>?) ?? [];
    final rainProbs = (hourly['precipitation_probability'] as List<dynamic>?) ?? [];
    final codes = (hourly['weather_code'] as List<dynamic>?) ?? [];
    final windSpeeds = (hourly['wind_speed_10m'] as List<dynamic>?) ?? [];
    final humidities = (hourly['relative_humidity_2m'] as List<dynamic>?) ?? [];

    final List<HourlyForecastModel> list = [];
    final now = DateTime.now();

    for (int i = 0; i < times.length && i < 24; i++) {
      final t = DateTime.tryParse(times[i]) ?? now.add(Duration(hours: i));
      final isDay = t.hour >= 6 && t.hour < 19;
      final wCode = (codes.length > i ? (codes[i] as num).toInt() : 0);
      final parsed = _mapWmoCodeToCondition(wCode, isDay: isDay);

      list.add(HourlyForecastModel(
        time: t,
        temperature: (temps.length > i ? (temps[i] as num).toDouble() : 20.0),
        feelsLike: (feels.length > i ? (feels[i] as num).toDouble() : 20.0),
        condition: parsed['condition']!,
        description: parsed['description']!,
        iconCode: parsed['iconCode']!,
        rainProbability: (rainProbs.length > i ? (rainProbs[i] as num?)?.round() ?? 0 : 0),
        windSpeed: (windSpeeds.length > i ? (windSpeeds[i] as num).toDouble() / 3.6 : 3.0),
        humidity: (humidities.length > i ? (humidities[i] as num?)?.round() ?? 50 : 50),
      ));
    }
    return list;
  }

  Map<String, String> _mapWmoCodeToCondition(int code, {bool isDay = true}) {
    final suffix = isDay ? 'd' : 'n';
    if (code == 0) {
      return {'condition': 'Clear', 'description': 'Clear sky', 'iconCode': '01$suffix'};
    } else if (code == 1 || code == 2) {
      return {'condition': 'Clouds', 'description': 'Partly cloudy', 'iconCode': '02$suffix'};
    } else if (code == 3) {
      return {'condition': 'Clouds', 'description': 'Overcast', 'iconCode': '04$suffix'};
    } else if (code == 45 || code == 48) {
      return {'condition': 'Fog', 'description': 'Foggy', 'iconCode': '50$suffix'};
    } else if (code >= 51 && code <= 55) {
      return {'condition': 'Drizzle', 'description': 'Light drizzle', 'iconCode': '09$suffix'};
    } else if (code >= 61 && code <= 67) {
      return {'condition': 'Rain', 'description': 'Rain showers', 'iconCode': '10$suffix'};
    } else if (code >= 71 && code <= 77) {
      return {'condition': 'Snow', 'description': 'Snowfall', 'iconCode': '13$suffix'};
    } else if (code >= 80 && code <= 82) {
      return {'condition': 'Rain', 'description': 'Heavy showers', 'iconCode': '09$suffix'};
    } else if (code >= 85 && code <= 86) {
      return {'condition': 'Snow', 'description': 'Snow showers', 'iconCode': '13$suffix'};
    } else if (code >= 95 && code <= 99) {
      return {'condition': 'Thunderstorm', 'description': 'Thunderstorm with rain', 'iconCode': '11$suffix'};
    }
    return {'condition': 'Clear', 'description': 'Clear sky', 'iconCode': '01$suffix'};
  }
}
