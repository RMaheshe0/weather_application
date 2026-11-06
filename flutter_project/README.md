# SkyPulse Weather — Flutter & Material 3 Android Application

SkyPulse is a modern, responsive, and feature-complete weather forecasting application built with **Flutter 3.35+**, **Dart (sound null safety)**, **Provider architecture**, and **Material 3**.

---

## 📱 Features

1. **Screen 1: Home / Real-Time Weather**
   - Dynamic animated backgrounds adapting to weather (Sunny, Rainy, Cloudy, Snowy, Night).
   - Real-time temperature, feels-like, min/max range, weather condition icon and description.
   - 6-metric weather grid: Humidity, Wind speed & direction, Atmospheric pressure, Visibility, Sunrise, and Sunset.
   - City search bar with live auto-complete and GPS current location lookup.
   - Pull-to-refresh & favorite city toggle.

2. **Screen 2: 24-Hour Hourly Forecast**
   - Interactive `fl_chart` smooth bezier temperature graph.
   - Horizontally scrollable and detailed vertical breakdown for the next 24 hours.
   - Precipitation probability percentage and wind speed per hour.

3. **Screen 3: 7-Day Extended Forecast**
   - Day names (Today, Tomorrow, Weekdays) with visual temperature range indicators.
   - Tap-to-expand details showing wind speed, UV index, sunrise, and sunset times.

4. **Screen 4: Saved Favorite Cities**
   - Add new cities to favorites.
   - Swipe-to-dismiss or button removal with Undo snackbar.
   - Prevents duplicate cities.
   - Shows live cached temperatures and weather badges for each city.
   - Full persistence across app restarts via `SharedPreferences`.

5. **Screen 5: Settings & Customization**
   - Temperature Unit: Celsius (°C) or Fahrenheit (°F).
   - Wind Speed Unit: km/h or m/s.
   - Theme Mode: Light, Dark, or System Default.
   - OpenWeatherMap custom API key input with immediate refresh.
   - Android system location permission launcher.

---

## 🛠 Tech Stack

- **Framework**: Flutter 3.35 or newer
- **Language**: Dart (null safe)
- **State Management**: `provider` (6.1.2) with `ChangeNotifier`
- **Charts**: `fl_chart` (0.68.0)
- **Networking**: `http` (1.2.1)
- **Persistence**: `shared_preferences` (2.2.3)
- **Geolocation**: `geolocator` (11.0.0) & `geocoding` (3.0.0)
- **Design**: Material 3 Design System

---

## 🔑 Weather API Configuration

SkyPulse is engineered with **dual live meteorological engines**:
1. **Zero-Configuration Mode (Default)**:
   Powered by the open-access WMO-compliant high-resolution Open-Meteo service. It works **immediately out-of-the-box** on any Android device without waiting for API keys to activate!
2. **OpenWeatherMap Integration**:
   - Register for a free API key at [openweathermap.org](https://openweathermap.org/api).
   - Provide your key via command line when running the app:
     ```bash
     flutter run --dart-define=OWM_KEY=your_actual_api_key_here
     ```
   - OR simply tap **Settings (Gear icon) -> OpenWeatherMap API Key** directly inside the running app and enter your key!

---

## 🚀 How to Run the Application

### Prerequisites
- Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.35.0 or newer).
- Install Android Studio or VS Code with Flutter extensions.
- An Android Emulator (API level 24+) or a physical Android device with USB debugging enabled.

### Steps
1. Navigate to the project directory:
   ```bash
   cd flutter_project
   ```
2. Install all dependencies:
   ```bash
   flutter pub get
   ```
3. Check connected Android devices:
   ```bash
   flutter devices
   ```
4. Run the app on your Android device:
   ```bash
   flutter run
   ```

---

## 🧪 Running Widget Tests

To execute the automated widget and unit tests:
```bash
flutter test
```
Or run specifically the weather widget suite:
```bash
flutter test test/widget_test.dart
```

---

## 📦 How to Generate a Release APK

To build an optimized, standalone release APK for installation on Android phones:

### 1. Build a Release APK (Single APK or split per ABI)
```bash
flutter build apk --release
```
The output APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

To create smaller APKs split by target CPU architecture (arm64-v8a, armeabi-v7a):
```bash
flutter build apk --split-per-abi --release
```

### 2. Build an Android App Bundle (for Google Play Store)
```bash
flutter build appbundle --release
```
The bundle will be generated at:
`build/app/outputs/bundle/release/app-release.aab`

---

## 📂 Project Architecture

```
flutter_project/
├── pubspec.yaml
├── README.md
├── test/
│   └── widget_test.dart
├── android/
│   └── app/src/main/AndroidManifest.xml
└── lib/
    ├── main.dart
    ├── models/
    │   ├── weather_model.dart
    │   ├── forecast_model.dart
    │   └── city_model.dart
    ├── services/
    │   ├── weather_service.dart
    │   ├── location_service.dart
    │   └── storage_service.dart
    ├── providers/
    │   └── weather_provider.dart
    ├── screens/
    │   ├── home_screen.dart
    │   ├── hourly_forecast_screen.dart
    │   ├── weekly_forecast_screen.dart
    │   ├── saved_cities_screen.dart
    │   └── settings_screen.dart
    ├── widgets/
    │   ├── current_weather_card.dart
    │   ├── hourly_forecast_card.dart
    │   ├── daily_forecast_card.dart
    │   ├── weather_details_card.dart
    │   ├── city_search_bar.dart
    │   ├── weather_chart.dart
    │   └── bottom_navigation_bar.dart
    └── utils/
        ├── app_theme.dart
        ├── weather_icons.dart
        └── constants.dart
```
