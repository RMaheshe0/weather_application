import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skypulse_weather/models/weather_model.dart';
import 'package:skypulse_weather/models/forecast_model.dart';
import 'package:skypulse_weather/providers/weather_provider.dart';
import 'package:skypulse_weather/widgets/current_weather_card.dart';
import 'package:skypulse_weather/widgets/weather_details_card.dart';

void main() {
  group('SkyPulse Weather Widget Tests', () {
    late WeatherModel mockWeather;
    late WeatherProvider mockProvider;

    setUp(() {
      mockWeather = WeatherModel(
        cityName: 'Tokyo',
        country: 'JP',
        latitude: 35.6762,
        longitude: 139.6503,
        temperature: 22.4,
        feelsLike: 23.0,
        tempMin: 18.0,
        tempMax: 25.0,
        humidity: 62,
        windSpeed: 4.5,
        windDegree: 180,
        pressure: 1012,
        visibilityKm: 10.0,
        condition: 'Clear',
        description: 'Clear sunny sky',
        iconCode: '01d',
        dateTime: DateTime.now(),
        sunrise: DateTime.now().subtract(const Duration(hours: 6)),
        sunset: DateTime.now().add(const Duration(hours: 6)),
        uvIndex: 6,
      );

      mockProvider = WeatherProvider();
    });

    testWidgets('CurrentWeatherCard renders city name, temperature, and condition', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentWeatherCard(
              weather: mockWeather,
              provider: mockProvider,
            ),
          ),
        ),
      );

      // Verify that City name is displayed
      expect(find.textContaining('Tokyo'), findsOneWidget);

      // Verify that formatted temperature is displayed
      expect(find.text('22°C'), findsOneWidget);

      // Verify that weather description is displayed
      expect(find.text('CLEAR SUNNY SKY'), findsOneWidget);

      // Verify Min/Max statistics are displayed
      expect(find.text('Min'), findsOneWidget);
      expect(find.text('Max'), findsOneWidget);
      expect(find.text('18°C'), findsOneWidget);
      expect(find.text('25°C'), findsOneWidget);
    });

    testWidgets('WeatherDetailsCard displays humidity, pressure, and wind metrics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeatherDetailsCard(
              weather: mockWeather,
              provider: mockProvider,
            ),
          ),
        ),
      );

      expect(find.text('Weather Details'), findsOneWidget);
      expect(find.text('Humidity'), findsOneWidget);
      expect(find.text('62%'), findsOneWidget);
      expect(find.text('Pressure'), findsOneWidget);
      expect(find.text('1012 hPa'), findsOneWidget);
      expect(find.text('Visibility'), findsOneWidget);
      expect(find.text('10.0 km'), findsOneWidget);
    });
  });
}
