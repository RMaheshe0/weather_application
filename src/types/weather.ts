export interface WeatherData {
  cityName: string;
  country: string;
  latitude: number;
  longitude: number;
  temperature: number; // Celsius
  feelsLike: number;
  tempMin: number;
  tempMax: number;
  humidity: number;
  windSpeed: number; // m/s
  windDegree: number;
  pressure: number; // hPa
  visibilityKm: number;
  condition: string;
  description: string;
  iconCode: string;
  isNight: boolean;
  dateTime: string;
  sunrise: string;
  sunset: string;
  uvIndex: number;
  cloudiness: number;
}

export interface HourlyForecastItem {
  time: string; // ISO or formatted
  hourLabel: string;
  temperature: number;
  feelsLike: number;
  condition: string;
  description: string;
  iconCode: string;
  rainProbability: number;
  windSpeed: number; // m/s
  humidity: number;
}

export interface DailyForecastItem {
  date: string;
  dayName: string;
  tempMin: number;
  tempMax: number;
  tempDay: number;
  condition: string;
  description: string;
  iconCode: string;
  rainProbability: number;
  windSpeed: number;
  uvIndex: number;
  sunrise: string;
  sunset: string;
}

export interface SavedCity {
  name: string;
  country: string;
  state?: string;
  latitude: number;
  longitude: number;
  currentTemp?: number;
  condition?: string;
  iconCode?: string;
}

export type TempUnit = 'celsius' | 'fahrenheit';
export type WindUnit = 'kmh' | 'ms';
export type ThemePref = 'system' | 'light' | 'dark';
