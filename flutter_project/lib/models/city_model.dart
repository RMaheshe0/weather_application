import 'dart:convert';

class CityModel {
  final String name;
  final String country;
  final String? state;
  final double latitude;
  final double longitude;
  final double? currentTemp;
  final String? condition;
  final String? iconCode;

  CityModel({
    required this.name,
    required this.country,
    this.state,
    required this.latitude,
    required this.longitude,
    this.currentTemp,
    this.condition,
    this.iconCode,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      name: (json['name'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
      state: json['state'] as String?,
      latitude: (json['lat'] as num?)?.toDouble() ?? (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['lon'] as num?)?.toDouble() ?? (json['longitude'] as num?)?.toDouble() ?? 0.0,
      currentTemp: (json['currentTemp'] as num?)?.toDouble(),
      condition: json['condition'] as String?,
      iconCode: json['iconCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'country': country,
    'state': state,
    'latitude': latitude,
    'longitude': longitude,
    'currentTemp': currentTemp,
    'condition': condition,
    'iconCode': iconCode,
  };

  CityModel copyWith({
    String? name,
    String? country,
    String? state,
    double? latitude,
    double? longitude,
    double? currentTemp,
    String? condition,
    String? iconCode,
  }) {
    return CityModel(
      name: name ?? this.name,
      country: country ?? this.country,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      currentTemp: currentTemp ?? this.currentTemp,
      condition: condition ?? this.condition,
      iconCode: iconCode ?? this.iconCode,
    );
  }

  static String encodeList(List<CityModel> cities) =>
      jsonEncode(cities.map((city) => city.toJson()).toList());

  static List<CityModel> decodeList(String str) {
    if (str.isEmpty) return [];
    final List<dynamic> list = jsonDecode(str);
    return list.map((item) => CityModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CityModel &&
          runtimeType == other.runtimeType &&
          name.toLowerCase() == other.name.toLowerCase() &&
          country.toLowerCase() == other.country.toLowerCase();

  @override
  int get hashCode => name.toLowerCase().hashCode ^ country.toLowerCase().hashCode;
}
