class WeatherModel {
  final String cityName;
  final String country;
  final double latitude;
  final double longitude;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed; // stored in m/s internally
  final int windDegree;
  final int pressure; // hPa
  final double visibilityKm; // in km
  final String condition;
  final String description;
  final String iconCode;
  final DateTime dateTime;
  final DateTime sunrise;
  final DateTime sunset;
  final int uvIndex;
  final int cloudiness;

  WeatherModel({
    required this.cityName,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.windDegree,
    required this.pressure,
    required this.visibilityKm,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.dateTime,
    required this.sunrise,
    required this.sunset,
    this.uvIndex = 0,
    this.cloudiness = 0,
  });

  /// Factory constructor to parse OpenWeatherMap current weather response JSON
  factory WeatherModel.fromOpenWeatherMapJson(Map<String, dynamic> json) {
    final weatherList = json['weather'] as List<dynamic>? ?? [];
    final firstWeather = weatherList.isNotEmpty
        ? weatherList[0] as Map<String, dynamic>
        : <String, dynamic>{};

    final main = json['main'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final sys = json['sys'] as Map<String, dynamic>? ?? {};
    final coord = json['coord'] as Map<String, dynamic>? ?? {};

    final sunriseEpoch = (sys['sunrise'] as int?) ?? 0;
    final sunsetEpoch = (sys['sunset'] as int?) ?? 0;
    final dtEpoch = (json['dt'] as int?) ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return WeatherModel(
      cityName: (json['name'] as String?)?.isNotEmpty == true
          ? json['name'] as String
          : 'Unknown Location',
      country: (sys['country'] as String?) ?? '',
      latitude: (coord['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (coord['lon'] as num?)?.toDouble() ?? 0.0,
      temperature: (main['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0.0,
      tempMin: (main['temp_min'] as num?)?.toDouble() ?? 0.0,
      tempMax: (main['temp_max'] as num?)?.toDouble() ?? 0.0,
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      windDegree: (wind['deg'] as num?)?.toInt() ?? 0,
      pressure: (main['pressure'] as num?)?.toInt() ?? 1013,
      visibilityKm: ((json['visibility'] as num?)?.toDouble() ?? 10000.0) / 1000.0,
      condition: (firstWeather['main'] as String?) ?? 'Clear',
      description: (firstWeather['description'] as String?) ?? 'Clear sky',
      iconCode: (firstWeather['icon'] as String?) ?? '01d',
      dateTime: DateTime.fromMillisecondsSinceEpoch(dtEpoch * 1000),
      sunrise: DateTime.fromMillisecondsSinceEpoch(sunriseEpoch * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch(sunsetEpoch * 1000),
      cloudiness: (json['clouds']?['all'] as num?)?.toInt() ?? 0,
    );
  }

  /// Converts wind degree to cardinal direction (N, NE, E, SE, S, SW, W, NW)
  String get windDirectionCardinal {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((windDegree + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  /// Determine if it is currently nighttime based on sunrise and sunset
  bool get isNight {
    final now = dateTime;
    if (sunrise.year > 1970 && sunset.year > 1970) {
      return now.isBefore(sunrise) || now.isAfter(sunset);
    }
    return iconCode.endsWith('n');
  }

  Map<String, dynamic> toJson() => {
    'cityName': cityName,
    'country': country,
    'latitude': latitude,
    'longitude': longitude,
    'temperature': temperature,
    'feelsLike': feelsLike,
    'tempMin': tempMin,
    'tempMax': tempMax,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'windDegree': windDegree,
    'pressure': pressure,
    'visibilityKm': visibilityKm,
    'condition': condition,
    'description': description,
    'iconCode': iconCode,
    'dateTime': dateTime.toIso8601String(),
    'sunrise': sunrise.toIso8601String(),
    'sunset': sunset.toIso8601String(),
    'uvIndex': uvIndex,
    'cloudiness': cloudiness,
  };
}
