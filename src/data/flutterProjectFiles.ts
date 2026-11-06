// Dynamically load all Flutter project files using Vite's import.meta.glob
const rawProjectFiles = import.meta.glob('/flutter_project/**', {
  query: '?raw',
  import: 'default',
  eager: true,
}) as Record<string, string>;

export interface ProjectFile {
  path: string;
  name: string;
  category: 'config' | 'model' | 'service' | 'provider' | 'screen' | 'widget' | 'util' | 'test' | 'doc';
  description: string;
  code: string;
}

function getCategory(path: string): ProjectFile['category'] {
  if (path.includes('/models/')) return 'model';
  if (path.includes('/services/')) return 'service';
  if (path.includes('/providers/')) return 'provider';
  if (path.includes('/screens/')) return 'screen';
  if (path.includes('/widgets/')) return 'widget';
  if (path.includes('/utils/')) return 'util';
  if (path.includes('/test/')) return 'test';
  if (path.endsWith('.md')) return 'doc';
  return 'config';
}

function getDescription(path: string): string {
  if (path.includes('pubspec.yaml')) return 'Flutter manifest configuring packages: provider, http, fl_chart, shared_preferences, geolocator, intl.';
  if (path.includes('AndroidManifest.xml')) return 'Android permissions (INTERNET, GPS) and application metadata.';
  if (path.includes('main.dart')) return 'Entry point, Provider setup, Material 3 theme configuration, and navigation holder.';
  if (path.includes('weather_model.dart')) return 'Weather observation model with wind cardinal calculation and JSON serialization.';
  if (path.includes('forecast_model.dart')) return 'Hourly 24h & 7-day daily forecast models with precipitation probabilities.';
  if (path.includes('city_model.dart')) return 'Search & favorite city model with persistence helpers.';
  if (path.includes('weather_service.dart')) return 'API service for OpenWeatherMap and zero-key open meteorological fallback.';
  if (path.includes('location_service.dart')) return 'GPS geolocation and reverse geocoding via Geolocator.';
  if (path.includes('storage_service.dart')) return 'SharedPreferences wrapper for favorite cities, units, and themes.';
  if (path.includes('weather_provider.dart')) return 'ChangeNotifier provider managing real-time state, forecasts, and saved cities.';
  if (path.includes('home_screen.dart')) return 'Screen 1: Weather dashboard with dynamic gradient, hero card, search, and details.';
  if (path.includes('hourly_forecast_screen.dart')) return 'Screen 2: 24-Hour forecast with fl_chart interactive curve and hourly cards.';
  if (path.includes('weekly_forecast_screen.dart')) return 'Screen 3: 7-Day forecast with expandable cards and temperature range bars.';
  if (path.includes('saved_cities_screen.dart')) return 'Screen 4: Saved favorite cities with duplicate prevention and swipe-to-delete.';
  if (path.includes('settings_screen.dart')) return 'Screen 5: Settings for Celsius/Fahrenheit, km/h vs m/s, theme, and API keys.';
  if (path.includes('current_weather_card.dart')) return 'Hero weather card with condition icon, min/max, and feels-like temperature.';
  if (path.includes('weather_details_card.dart')) return '6-metric grid for humidity, wind, pressure, visibility, sunrise, and sunset.';
  if (path.includes('weather_chart.dart')) return 'fl_chart LineChart implementation with curved line, dots, and tooltips.';
  if (path.includes('hourly_forecast_card.dart')) return 'Card displaying hour, temperature, condition icon, and rain probability.';
  if (path.includes('daily_forecast_card.dart')) return '7-day list item with expandable details and temperature visual bar.';
  if (path.includes('city_search_bar.dart')) return 'Search bar with debounced autocomplete and one-tap GPS button.';
  if (path.includes('bottom_navigation_bar.dart')) return 'Material 3 NavigationBar with 4 destinations: Home, Hourly, 7-Day, Saved.';
  if (path.includes('app_theme.dart')) return 'Material 3 Light and Dark themes, and dynamic weather-based gradient palettes.';
  if (path.includes('weather_icons.dart')) return 'Mapping weather condition strings to Material 3 icons and accent colors.';
  if (path.includes('constants.dart')) return 'App constants, API URLs, SharedPreferences keys, and unit enums.';
  if (path.includes('widget_test.dart')) return 'Automated Flutter widget tests verifying CurrentWeatherCard and WeatherDetailsCard.';
  if (path.includes('README.md')) return 'Instructions to run on Android devices, execute tests, and build release APK.';
  return 'Flutter project source file';
}

export const FLUTTER_PROJECT_FILES: ProjectFile[] = Object.entries(rawProjectFiles)
  .map(([rawPath, code]) => {
    // Strip leading /flutter_project/
    const relativePath = rawPath.replace(/^\/flutter_project\//, '');
    const segments = relativePath.split('/');
    const fileName = segments[segments.length - 1];

    return {
      path: relativePath,
      name: fileName,
      category: getCategory(relativePath),
      description: getDescription(relativePath),
      code: code || '',
    };
  })
  .sort((a, b) => {
    // Priority order: pubspec.yaml, AndroidManifest.xml, main.dart, models, services, providers, screens, widgets, utils, test, doc
    const order = ['pubspec.yaml', 'AndroidManifest.xml', 'main.dart'];
    const idxA = order.indexOf(a.name);
    const idxB = order.indexOf(b.name);
    if (idxA !== -1 && idxB !== -1) return idxA - idxB;
    if (idxA !== -1) return -1;
    if (idxB !== -1) return 1;
    return a.path.localeCompare(b.path);
  });
