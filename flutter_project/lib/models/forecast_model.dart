class HourlyForecastModel {
  final DateTime time;
  final double temperature;
  final double feelsLike;
  final String condition;
  final String description;
  final String iconCode;
  final int rainProbability; // 0 to 100%
  final double windSpeed; // m/s
  final int humidity;

  HourlyForecastModel({
    required this.time,
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.rainProbability,
    required this.windSpeed,
    required this.humidity,
  });

  factory HourlyForecastModel.fromOpenWeatherMapJson(Map<String, dynamic> json) {
    final weatherList = json['weather'] as List<dynamic>? ?? [];
    final firstWeather = weatherList.isNotEmpty
        ? weatherList[0] as Map<String, dynamic>
        : <String, dynamic>{};
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final dtEpoch = (json['dt'] as int?) ?? 0;
    final pop = (json['pop'] as num?)?.toDouble() ?? 0.0;

    return HourlyForecastModel(
      time: DateTime.fromMillisecondsSinceEpoch(dtEpoch * 1000),
      temperature: (main['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0.0,
      condition: (firstWeather['main'] as String?) ?? 'Clear',
      description: (firstWeather['description'] as String?) ?? '',
      iconCode: (firstWeather['icon'] as String?) ?? '01d',
      rainProbability: (pop * 100).round(),
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'temperature': temperature,
    'feelsLike': feelsLike,
    'condition': condition,
    'description': description,
    'iconCode': iconCode,
    'rainProbability': rainProbability,
    'windSpeed': windSpeed,
    'humidity': humidity,
  };
}

class DailyForecastModel {
  final DateTime date;
  final String dayName;
  final double tempMin;
  final double tempMax;
  final double tempDay;
  final String condition;
  final String description;
  final String iconCode;
  final int rainProbability; // 0 to 100%
  final int humidity;
  final double windSpeed;
  final int uvIndex;
  final DateTime? sunrise;
  final DateTime? sunset;

  DailyForecastModel({
    required this.date,
    required this.dayName,
    required this.tempMin,
    required this.tempMax,
    required this.tempDay,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.rainProbability,
    required this.humidity,
    required this.windSpeed,
    this.uvIndex = 0,
    this.sunrise,
    this.sunset,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'dayName': dayName,
    'tempMin': tempMin,
    'tempMax': tempMax,
    'tempDay': tempDay,
    'condition': condition,
    'description': description,
    'iconCode': iconCode,
    'rainProbability': rainProbability,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'uvIndex': uvIndex,
    'sunrise': sunrise?.toIso8601String(),
    'sunset': sunset?.toIso8601String(),
  };
}
