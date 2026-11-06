import React, { useState, useEffect, useRef } from 'react';
import {
  Search,
  MapPin,
  RefreshCw,
  Settings as SettingsIcon,
  Heart,
  Calendar,
  Clock,
  Sun,
  Cloud,
  CloudRain,
  CloudSnow,
  CloudLightning,
  Wind,
  Droplets,
  Eye,
  Gauge,
  Sunrise,
  Sunset,
  ChevronDown,
  ChevronUp,
  ArrowRight,
  Plus,
  Trash2,
  Navigation,
  Check,
  X,
  AlertCircle,
  Sparkles,
} from 'lucide-react';
import { WeatherData, HourlyForecastItem, DailyForecastItem, SavedCity, TempUnit, WindUnit, ThemePref } from '../types/weather';
import { LiveWeatherService } from '../services/liveWeatherService';

interface AndroidSimulatorProps {
  initialCity?: string;
  onOpenSettingsFromParent?: () => void;
}

export const AndroidSimulator: React.FC<AndroidSimulatorProps> = ({ initialCity = 'London' }) => {
  const [activeTab, setActiveTab] = useState<'home' | 'hourly' | 'weekly' | 'saved' | 'settings'>('home');
  const [currentWeather, setCurrentWeather] = useState<WeatherData | null>(null);
  const [hourlyForecast, setHourlyForecast] = useState<HourlyForecastItem[]>([]);
  const [dailyForecast, setDailyForecast] = useState<DailyForecastItem[]>([]);
  const [savedCities, setSavedCities] = useState<SavedCity[]>([
    { name: 'London', country: 'GB', latitude: 51.5074, longitude: -0.1278, currentTemp: 16, condition: 'Clear', iconCode: '01d' },
    { name: 'Tokyo', country: 'JP', latitude: 35.6762, longitude: 139.6503, currentTemp: 22, condition: 'Clouds', iconCode: '02d' },
    { name: 'New York', country: 'US', latitude: 40.7128, longitude: -74.0060, currentTemp: 18, condition: 'Rain', iconCode: '10d' },
  ]);

  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<SavedCity[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [showSearchDropdown, setShowSearchDropdown] = useState(false);

  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Settings
  const [tempUnit, setTempUnit] = useState<TempUnit>('celsius');
  const [windUnit, setWindUnit] = useState<WindUnit>('kmh');
  const [themePref, setThemePref] = useState<ThemePref>('system');
  const [owmApiKey, setOwmApiKey] = useState<string>('');
  const [isApiKeyModalOpen, setIsApiKeyModalOpen] = useState(false);
  const [apiKeyInput, setApiKeyInput] = useState('');

  // Add City Dialog
  const [isAddCityModalOpen, setIsAddCityModalOpen] = useState(false);
  const [newCityInput, setNewCityInput] = useState('');
  const [addCitySuggestions, setAddCitySuggestions] = useState<SavedCity[]>([]);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Expanded Day in 7-day forecast
  const [expandedDayIndex, setExpandedDayIndex] = useState<number | null>(0);

  // Hovered Chart spot
  const [hoveredChartIndex, setHoveredChartIndex] = useState<number | null>(null);

  // System status clock
  const [currentTimeStr, setCurrentTimeStr] = useState('12:00');

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setCurrentTimeStr(now.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit', hour12: false }));
    };
    updateTime();
    const timer = setInterval(updateTime, 30000);
    return () => clearInterval(timer);
  }, []);

  // Show toast utility
  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  // Load saved preferences from localStorage
  useEffect(() => {
    try {
      const savedU = localStorage.getItem('skypulse_temp_unit');
      if (savedU === 'fahrenheit' || savedU === 'celsius') setTempUnit(savedU);

      const savedW = localStorage.getItem('skypulse_wind_unit');
      if (savedW === 'ms' || savedW === 'kmh') setWindUnit(savedW);

      const savedT = localStorage.getItem('skypulse_theme_mode');
      if (savedT === 'light' || savedT === 'dark' || savedT === 'system') setThemePref(savedT);

      const savedK = localStorage.getItem('skypulse_owm_api_key');
      if (savedK) {
        setOwmApiKey(savedK);
        setApiKeyInput(savedK);
      }

      const savedC = localStorage.getItem('skypulse_saved_cities');
      if (savedC) {
        setSavedCities(JSON.parse(savedC));
      }
    } catch (_) {}
  }, []);

  // Save changes to localStorage
  const updateTempUnit = (u: TempUnit) => {
    setTempUnit(u);
    localStorage.setItem('skypulse_temp_unit', u);
  };
  const updateWindUnit = (w: WindUnit) => {
    setWindUnit(w);
    localStorage.setItem('skypulse_wind_unit', w);
  };
  const updateThemePref = (t: ThemePref) => {
    setThemePref(t);
    localStorage.setItem('skypulse_theme_mode', t);
  };
  const saveApiKey = () => {
    setOwmApiKey(apiKeyInput.trim());
    localStorage.setItem('skypulse_owm_api_key', apiKeyInput.trim());
    setIsApiKeyModalOpen(false);
    showToast('OpenWeatherMap API Key updated.');
    if (currentWeather) {
      loadWeatherByCoords(currentWeather.latitude, currentWeather.longitude, currentWeather.cityName, currentWeather.country);
    }
  };

  // Formatters
  const formatTemp = (celsius: number) => {
    if (tempUnit === 'fahrenheit') {
      const f = Math.round((celsius * 9) / 5 + 32);
      return `${f}°F`;
    }
    return `${Math.round(celsius)}°C`;
  };

  const formatWind = (ms: number) => {
    if (windUnit === 'kmh') {
      return `${(ms * 3.6).toFixed(1)} km/h`;
    }
    return `${ms.toFixed(1)} m/s`;
  };

  // Load weather for city
  const loadWeatherForCity = async (city: string) => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const cities = await LiveWeatherService.searchCities(city);
      if (cities.length === 0) {
        throw new Error(`City "${city}" not found.`);
      }
      const target = cities[0];
      await loadWeatherByCoords(target.latitude, target.longitude, target.name, target.country);
    } catch (err: any) {
      setErrorMessage(err.message || 'Failed to load weather');
      setIsLoading(false);
    }
  };

  const loadWeatherByCoords = async (lat: number, lon: number, cityName?: string, countryName?: string) => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const res = await LiveWeatherService.fetchWeather(lat, lon, cityName, countryName, owmApiKey);
      setCurrentWeather(res.current);
      setHourlyForecast(res.hourly);
      setDailyForecast(res.daily);

      // Update saved city current temp if exists
      setSavedCities((prev) => {
        const next = prev.map((c) => {
          if (c.name.toLowerCase() === res.current.cityName.toLowerCase()) {
            return {
              ...c,
              currentTemp: res.current.temperature,
              condition: res.current.condition,
              iconCode: res.current.iconCode,
            };
          }
          return c;
        });
        localStorage.setItem('skypulse_saved_cities', JSON.stringify(next));
        return next;
      });
    } catch (err: any) {
      setErrorMessage(err.message || 'Network error fetching weather');
    } finally {
      setIsLoading(false);
    }
  };

  // Get GPS Location
  const handleUseGpsLocation = () => {
    if (!navigator.geolocation) {
      showToast('Geolocation is not supported by your browser.');
      return;
    }
    setIsLoading(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        loadWeatherByCoords(pos.coords.latitude, pos.coords.longitude, 'Current Location');
        showToast('Acquired current GPS location');
      },
      (err) => {
        setIsLoading(false);
        showToast('GPS permission denied or unavailable. Using London.');
      },
      { timeout: 10000 }
    );
  };

  // Initial load
  useEffect(() => {
    loadWeatherForCity(initialCity);
  }, []);

  // Search autocomplete
  const searchTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const handleSearchChange = (val: string) => {
    setSearchQuery(val);
    if (searchTimeoutRef.current) clearTimeout(searchTimeoutRef.current);
    if (val.trim().length < 2) {
      setSearchResults([]);
      setShowSearchDropdown(false);
      return;
    }
    setIsSearching(true);
    searchTimeoutRef.current = setTimeout(async () => {
      const results = await LiveWeatherService.searchCities(val);
      setSearchResults(results);
      setIsSearching(false);
      setShowSearchDropdown(true);
    }, 350);
  };

  const handleSelectSearchResult = (c: SavedCity) => {
    setSearchQuery('');
    setShowSearchDropdown(false);
    loadWeatherByCoords(c.latitude, c.longitude, c.name, c.country);
    setActiveTab('home');
  };

  // Favorite toggle
  const isCurrentSaved = currentWeather
    ? savedCities.some((c) => c.name.toLowerCase() === currentWeather.cityName.toLowerCase())
    : false;

  const toggleFavorite = () => {
    if (!currentWeather) return;
    if (isCurrentSaved) {
      const filtered = savedCities.filter((c) => c.name.toLowerCase() !== currentWeather.cityName.toLowerCase());
      setSavedCities(filtered);
      localStorage.setItem('skypulse_saved_cities', JSON.stringify(filtered));
      showToast(`${currentWeather.cityName} removed from favorites`);
    } else {
      const newCity: SavedCity = {
        name: currentWeather.cityName,
        country: currentWeather.country,
        latitude: currentWeather.latitude,
        longitude: currentWeather.longitude,
        currentTemp: currentWeather.temperature,
        condition: currentWeather.condition,
        iconCode: currentWeather.iconCode,
      };
      const next = [...savedCities, newCity];
      setSavedCities(next);
      localStorage.setItem('skypulse_saved_cities', JSON.stringify(next));
      showToast(`${currentWeather.cityName} added to favorites!`);
    }
  };

  const removeCity = (cityName: string) => {
    const next = savedCities.filter((c) => c.name.toLowerCase() !== cityName.toLowerCase());
    setSavedCities(next);
    localStorage.setItem('skypulse_saved_cities', JSON.stringify(next));
    showToast(`${cityName} removed from favorites`);
  };

  const handleAddCitySearchChange = async (val: string) => {
    setNewCityInput(val);
    if (val.trim().length >= 2) {
      const res = await LiveWeatherService.searchCities(val);
      setAddCitySuggestions(res);
    } else {
      setAddCitySuggestions([]);
    }
  };

  const handleConfirmAddCity = (city: SavedCity) => {
    if (savedCities.some((c) => c.name.toLowerCase() === city.name.toLowerCase())) {
      showToast(`${city.name} is already saved!`);
      setIsAddCityModalOpen(false);
      return;
    }
    const next = [...savedCities, city];
    setSavedCities(next);
    localStorage.setItem('skypulse_saved_cities', JSON.stringify(next));
    showToast(`${city.name} added to favorites!`);
    setIsAddCityModalOpen(false);
    setNewCityInput('');
    setAddCitySuggestions([]);
  };

  // Weather Condition Icon helper
  const renderWeatherIcon = (condition: string, iconCode?: string, size = 28, className = '') => {
    const lower = condition.toLowerCase();
    const isNight = iconCode?.endsWith('n');

    if (lower.includes('thunder') || lower.includes('storm')) {
      return <CloudLightning size={size} className={`text-yellow-400 ${className}`} />;
    }
    if (lower.includes('rain') || lower.includes('drizzle')) {
      return <CloudRain size={size} className={`text-blue-400 ${className}`} />;
    }
    if (lower.includes('snow')) {
      return <CloudSnow size={size} className={`text-cyan-200 ${className}`} />;
    }
    if (lower.includes('cloud')) {
      return <Cloud size={size} className={`text-slate-300 ${className}`} />;
    }
    if (isNight) {
      return <Cloud size={size} className={`text-indigo-200 ${className}`} />;
    }
    return <Sun size={size} className={`text-amber-400 ${className}`} />;
  };

  // Dynamic Background Gradient
  const getDynamicBackground = () => {
    if (!currentWeather) return 'from-blue-600 via-indigo-600 to-slate-900';
    if (currentWeather.isNight) {
      return 'from-slate-950 via-slate-900 to-indigo-950';
    }
    const lower = currentWeather.condition.toLowerCase();
    if (lower.includes('snow')) {
      return 'from-sky-700 via-slate-600 to-blue-900';
    }
    if (lower.includes('rain') || lower.includes('thunder')) {
      return 'from-slate-900 via-blue-950 to-indigo-950';
    }
    if (lower.includes('cloud') || lower.includes('fog')) {
      return 'from-slate-700 via-slate-800 to-slate-900';
    }
    // Sunny
    return 'from-amber-500 via-orange-600 to-blue-700';
  };

  return (
    <div className="relative mx-auto flex flex-col items-center">
      {/* Device Frame */}
      <div className="relative w-[370px] sm:w-[395px] h-[780px] bg-neutral-900 rounded-[50px] p-[10px] shadow-[0_25px_60px_-15px_rgba(0,0,0,0.6)] border-[4px] border-neutral-700 ring-1 ring-neutral-800">
        {/* Device Punch Hole Camera */}
        <div className="absolute top-4 left-1/2 -translate-x-1/2 w-4 h-4 bg-black rounded-full z-50 ring-2 ring-neutral-800 flex items-center justify-center">
          <div className="w-1.5 h-1.5 bg-neutral-900 rounded-full" />
        </div>

        {/* Device Screen Screen Surface */}
        <div className={`relative w-full h-full rounded-[40px] overflow-hidden flex flex-col bg-gradient-to-b ${getDynamicBackground()} text-white select-none transition-colors duration-700`}>
          {/* Animated Weather Atmosphere Particles */}
          <div className="absolute inset-0 pointer-events-none overflow-hidden opacity-30 z-0">
            {currentWeather?.condition.toLowerCase().includes('rain') && (
              <div className="absolute inset-0 bg-[radial-gradient(#38bdf8_1px,transparent_1px)] [background-size:16px_16px] animate-pulse" />
            )}
            {currentWeather?.condition.toLowerCase().includes('snow') && (
              <div className="absolute inset-0 bg-[radial-gradient(#ffffff_2px,transparent_2px)] [background-size:24px_24px] animate-bounce" />
            )}
            {!currentWeather?.isNight && currentWeather?.condition.toLowerCase().includes('clear') && (
              <div className="absolute -top-20 -right-20 w-72 h-72 bg-amber-400/25 rounded-full blur-3xl animate-pulse" />
            )}
          </div>

          {/* Android Status Bar */}
          <div className="relative z-30 pt-3 px-6 pb-1 flex items-center justify-between text-xs font-semibold tracking-tight text-white/90">
            <span>{currentTimeStr}</span>
            <div className="flex items-center space-x-1.5">
              <span className="text-[10px] font-bold px-1 py-0.5 rounded bg-white/20">5G</span>
              <div className="w-3.5 h-2.5 border border-white rounded-sm p-[1px] flex items-center">
                <div className="h-full w-full bg-white rounded-2xs" />
              </div>
            </div>
          </div>

          {/* Top Bar for Screens */}
          <div className="relative z-20 px-4 pt-1 pb-2 flex items-center justify-between">
            <div className="flex items-center space-x-1.5">
              <span className="font-bold text-base tracking-tight drop-shadow">
                {activeTab === 'home' && (currentWeather?.cityName || 'SkyPulse')}
                {activeTab === 'hourly' && '24-Hour Forecast'}
                {activeTab === 'weekly' && '7-Day Forecast'}
                {activeTab === 'saved' && 'Saved Cities'}
                {activeTab === 'settings' && 'Settings'}
              </span>
              {activeTab === 'home' && currentWeather && (
                <span className="text-xs text-white/70 font-medium">({currentWeather.country})</span>
              )}
            </div>

            <div className="flex items-center space-x-1">
              {activeTab === 'home' && currentWeather && (
                <button
                  onClick={toggleFavorite}
                  className="p-2 rounded-full hover:bg-white/20 active:scale-95 transition"
                  title="Toggle Favorite"
                >
                  <Heart
                    size={19}
                    className={isCurrentSaved ? 'fill-rose-400 text-rose-400' : 'text-white'}
                  />
                </button>
              )}

              <button
                onClick={() => {
                  if (currentWeather) {
                    loadWeatherByCoords(currentWeather.latitude, currentWeather.longitude, currentWeather.cityName, currentWeather.country);
                  } else {
                    loadWeatherForCity(initialCity);
                  }
                }}
                disabled={isLoading}
                className="p-2 rounded-full hover:bg-white/20 active:scale-95 transition"
                title="Refresh Weather"
              >
                <RefreshCw size={18} className={isLoading ? 'animate-spin' : ''} />
              </button>

              <button
                onClick={() => setActiveTab(activeTab === 'settings' ? 'home' : 'settings')}
                className={`p-2 rounded-full transition ${activeTab === 'settings' ? 'bg-white/30' : 'hover:bg-white/20'}`}
                title="Settings"
              >
                <SettingsIcon size={18} />
              </button>
            </div>
          </div>

          {/* Screen Content Container */}
          <div className="relative z-10 flex-1 overflow-y-auto px-4 pb-20 scrollbar-none">
            {/* Toast Notification */}
            {toastMessage && (
              <div className="fixed top-14 left-1/2 -translate-x-1/2 bg-black/80 backdrop-blur-md text-white text-xs px-3.5 py-1.5 rounded-full shadow-lg z-50 animate-fade-in border border-white/20 flex items-center space-x-1.5">
                <Sparkles size={13} className="text-amber-400" />
                <span>{toastMessage}</span>
              </div>
            )}

            {/* TAB 1: HOME SCREEN */}
            {activeTab === 'home' && (
              <div className="space-y-4 pt-1">
                {/* Search Bar with GPS Button */}
                <div className="relative">
                  <div className="flex items-center bg-white/20 backdrop-blur-md rounded-2xl px-3 py-2 border border-white/30 shadow-sm focus-within:ring-2 focus-within:ring-white/50 transition">
                    <Search size={18} className="text-white/80 mr-2 shrink-0" />
                    <input
                      type="text"
                      placeholder="Search city, e.g. Tokyo..."
                      value={searchQuery}
                      onChange={(e) => handleSearchChange(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' && searchQuery.trim()) {
                          loadWeatherForCity(searchQuery.trim());
                          setShowSearchDropdown(false);
                          setSearchQuery('');
                        }
                      }}
                      className="bg-transparent text-white placeholder-white/60 text-xs w-full focus:outline-none"
                    />
                    {isSearching && <RefreshCw size={14} className="animate-spin text-white/80 mr-1.5 shrink-0" />}
                    {searchQuery && (
                      <button
                        onClick={() => {
                          setSearchQuery('');
                          setShowSearchDropdown(false);
                        }}
                        className="text-white/70 hover:text-white mr-1"
                      >
                        <X size={15} />
                      </button>
                    )}
                    <button
                      onClick={handleUseGpsLocation}
                      className="p-1 rounded-full bg-white/20 hover:bg-white/30 text-white shrink-0"
                      title="Use Current GPS"
                    >
                      <Navigation size={14} />
                    </button>
                  </div>

                  {/* Autocomplete Suggestions */}
                  {showSearchDropdown && searchResults.length > 0 && (
                    <div className="absolute top-12 left-0 right-0 bg-neutral-900/95 backdrop-blur-xl border border-white/20 rounded-2xl p-1.5 shadow-2xl z-50 max-h-56 overflow-y-auto">
                      {searchResults.map((city, idx) => (
                        <div
                          key={idx}
                          onClick={() => handleSelectSearchResult(city)}
                          className="flex items-center justify-between px-3 py-2 hover:bg-white/10 rounded-xl cursor-pointer transition text-xs"
                        >
                          <div className="flex items-center space-x-2">
                            <MapPin size={14} className="text-amber-400 shrink-0" />
                            <div>
                              <p className="font-semibold">{city.name}</p>
                              <p className="text-[10px] text-white/60">{[city.state, city.country].filter(Boolean).join(', ')}</p>
                            </div>
                          </div>
                          <span className="text-[10px] text-white/40">Select</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Loading State */}
                {isLoading && !currentWeather ? (
                  <div className="py-24 flex flex-col items-center justify-center space-y-3">
                    <RefreshCw size={36} className="animate-spin text-white/80" />
                    <p className="text-xs text-white/70 font-medium">Fetching real-time weather...</p>
                  </div>
                ) : errorMessage && !currentWeather ? (
                  /* Error State */
                  <div className="bg-white/15 backdrop-blur-lg rounded-3xl p-6 text-center border border-white/30 space-y-3 my-12">
                    <AlertCircle size={40} className="mx-auto text-rose-300" />
                    <p className="font-bold text-sm">Failed to Load Weather</p>
                    <p className="text-xs text-white/80">{errorMessage}</p>
                    <button
                      onClick={() => loadWeatherForCity(initialCity)}
                      className="px-4 py-1.5 bg-white text-slate-900 font-semibold rounded-full text-xs shadow hover:bg-white/90 active:scale-95 transition"
                    >
                      Try Again
                    </button>
                  </div>
                ) : currentWeather ? (
                  <>
                    {/* Hero Current Weather Card */}
                    <div className="bg-white/18 backdrop-blur-xl rounded-[28px] p-5 border border-white/30 shadow-lg text-center relative overflow-hidden">
                      <div className="flex items-center justify-center space-x-1.5 text-xs text-white/80 font-medium">
                        <MapPin size={14} className="text-white" />
                        <span>{currentWeather.cityName}, {currentWeather.country}</span>
                      </div>
                      <p className="text-[11px] text-white/70 mt-0.5">
                        {new Date().toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })} • {currentTimeStr}
                      </p>

                      <div className="my-3 flex items-center justify-center space-x-4">
                        {renderWeatherIcon(currentWeather.condition, currentWeather.iconCode, 64)}
                        <div className="text-left">
                          <div className="text-5xl font-light tracking-tight leading-none">
                            {formatTemp(currentWeather.temperature)}
                          </div>
                          <p className="text-[11px] font-bold tracking-wider uppercase text-white/90 mt-1">
                            {currentWeather.description}
                          </p>
                        </div>
                      </div>

                      {/* Stat Pill */}
                      <div className="bg-black/15 rounded-2xl py-2 px-3 flex items-center justify-around text-center text-xs">
                        <div>
                          <p className="text-[10px] text-white/70">Feels Like</p>
                          <p className="font-bold text-xs">{formatTemp(currentWeather.feelsLike)}</p>
                        </div>
                        <div className="w-[1px] h-6 bg-white/20" />
                        <div>
                          <p className="text-[10px] text-white/70">Min</p>
                          <p className="font-bold text-xs">{formatTemp(currentWeather.tempMin)}</p>
                        </div>
                        <div className="w-[1px] h-6 bg-white/20" />
                        <div>
                          <p className="text-[10px] text-white/70">Max</p>
                          <p className="font-bold text-xs">{formatTemp(currentWeather.tempMax)}</p>
                        </div>
                      </div>
                    </div>

                    {/* Hourly Preview Horizontal Scroller */}
                    <div>
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs font-bold text-white/95">Hourly Forecast</span>
                        <button
                          onClick={() => setActiveTab('hourly')}
                          className="text-[11px] text-white/80 hover:text-white flex items-center space-x-0.5 font-semibold"
                        >
                          <span>See 24h</span>
                          <ArrowRight size={12} />
                        </button>
                      </div>

                      <div className="flex space-x-2.5 overflow-x-auto pb-1 scrollbar-none">
                        {hourlyForecast.slice(0, 8).map((hour, idx) => (
                          <div
                            key={idx}
                            className={`flex flex-col items-center justify-between min-w-[72px] py-2.5 px-2 rounded-2xl border backdrop-blur-md text-center transition ${
                              idx === 0
                                ? 'bg-white/30 border-white/50 ring-1 ring-white/50'
                                : 'bg-white/12 border-white/20 hover:bg-white/18'
                            }`}
                          >
                            <span className="text-[11px] font-semibold text-white/90">{hour.hourLabel}</span>
                            <div className="my-1.5">{renderWeatherIcon(hour.condition, hour.iconCode, 22)}</div>
                            <span className="text-xs font-bold">{formatTemp(hour.temperature)}</span>
                            <span className="text-[10px] text-sky-200 mt-1 font-medium">{hour.rainProbability}% rain</span>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* 6-Metric Weather Details Grid */}
                    <div className="bg-neutral-900/40 backdrop-blur-xl rounded-[24px] p-4 border border-white/20">
                      <p className="text-xs font-bold text-white/90 mb-3">Weather Details</p>
                      <div className="grid grid-cols-2 gap-2.5">
                        <div className="bg-white/10 rounded-2xl p-2.5 flex items-center space-x-3">
                          <div className="p-2 rounded-full bg-sky-500/20 text-sky-400">
                            <Droplets size={18} />
                          </div>
                          <div>
                            <p className="text-[10px] text-white/60">Humidity</p>
                            <p className="text-xs font-bold">{currentWeather.humidity}%</p>
                          </div>
                        </div>

                        <div className="bg-white/10 rounded-2xl p-2.5 flex items-center space-x-3">
                          <div className="p-2 rounded-full bg-teal-500/20 text-teal-400">
                            <Wind size={18} />
                          </div>
                          <div>
                            <p className="text-[10px] text-white/60">Wind</p>
                            <p className="text-xs font-bold">{formatWind(currentWeather.windSpeed)}</p>
                          </div>
                        </div>

                        <div className="bg-white/10 rounded-2xl p-2.5 flex items-center space-x-3">
                          <div className="p-2 rounded-full bg-purple-500/20 text-purple-400">
                            <Gauge size={18} />
                          </div>
                          <div>
                            <p className="text-[10px] text-white/60">Pressure</p>
                            <p className="text-xs font-bold">{currentWeather.pressure} hPa</p>
                          </div>
                        </div>

                        <div className="bg-white/10 rounded-2xl p-2.5 flex items-center space-x-3">
                          <div className="p-2 rounded-full bg-amber-500/20 text-amber-400">
                            <Eye size={18} />
                          </div>
                          <div>
                            <p className="text-[10px] text-white/60">Visibility</p>
                            <p className="text-xs font-bold">{currentWeather.visibilityKm.toFixed(1)} km</p>
                          </div>
                        </div>

                        <div className="bg-white/10 rounded-2xl p-2.5 flex items-center space-x-3">
                          <div className="p-2 rounded-full bg-orange-500/20 text-orange-400">
                            <Sunrise size={18} />
                          </div>
                          <div>
                            <p className="text-[10px] text-white/60">Sunrise</p>
                            <p className="text-xs font-bold">
                              {new Date(currentWeather.sunrise).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })}
                            </p>
                          </div>
                        </div>

                        <div className="bg-white/10 rounded-2xl p-2.5 flex items-center space-x-3">
                          <div className="p-2 rounded-full bg-indigo-500/20 text-indigo-400">
                            <Sunset size={18} />
                          </div>
                          <div>
                            <p className="text-[10px] text-white/60">Sunset</p>
                            <p className="text-xs font-bold">
                              {new Date(currentWeather.sunset).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })}
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Quick 7-Day Banner */}
                    <div
                      onClick={() => setActiveTab('weekly')}
                      className="bg-white/15 backdrop-blur-xl rounded-2xl p-3.5 border border-white/20 flex items-center justify-between cursor-pointer hover:bg-white/20 transition active:scale-98"
                    >
                      <div className="flex items-center space-x-3">
                        <div className="p-2 bg-amber-400/20 rounded-xl text-amber-300">
                          <Calendar size={20} />
                        </div>
                        <div>
                          <p className="font-bold text-xs text-white">7-Day Extended Forecast</p>
                          <p className="text-[10px] text-white/70">Explore daily high/low temperatures</p>
                        </div>
                      </div>
                      <ArrowRight size={16} className="text-white/80" />
                    </div>
                  </>
                ) : null}
              </div>
            )}

            {/* TAB 2: HOURLY FORECAST (with fl_chart interactive curve simulator) */}
            {activeTab === 'hourly' && (
              <div className="space-y-4 pt-1">
                {/* SVG Temperature Curve Graph */}
                <div className="bg-neutral-900/50 backdrop-blur-xl rounded-[24px] p-4 border border-white/20">
                  <div className="flex items-center justify-between mb-3">
                    <p className="text-xs font-bold text-white">24h Temperature Trend</p>
                    <span className="text-[10px] text-amber-300 font-semibold">fl_chart Graph</span>
                  </div>

                  {/* SVG Line Chart */}
                  <div className="relative h-32 w-full pt-4">
                    {hourlyForecast.length > 0 && (() => {
                      const points = hourlyForecast.slice(0, 10);
                      const temps = points.map((p) => p.temperature);
                      const minT = Math.min(...temps) - 2;
                      const maxT = Math.max(...temps) + 2;
                      const range = maxT - minT || 1;

                      const width = 320;
                      const height = 90;
                      const stepX = width / (points.length - 1);

                      const coordinates = points.map((p, i) => {
                        const x = i * stepX;
                        const y = height - ((p.temperature - minT) / range) * height;
                        return { x, y, point: p };
                      });

                      const pathD = coordinates.reduce((acc, curr, idx, arr) => {
                        if (idx === 0) return `M ${curr.x} ${curr.y}`;
                        const prev = arr[idx - 1];
                        const cX = (prev.x + curr.x) / 2;
                        return `${acc} C ${cX} ${prev.y}, ${cX} ${curr.y}, ${curr.x} ${curr.y}`;
                      }, '');

                      const areaD = `${pathD} L ${width} ${height} L 0 ${height} Z`;

                      return (
                        <svg viewBox={`0 0 ${width} ${height}`} className="w-full h-full overflow-visible">
                          <defs>
                            <linearGradient id="chartGrad" x1="0" y1="0" x2="0" y2="1">
                              <stop offset="0%" stopColor="#fbbf24" stopOpacity="0.4" />
                              <stop offset="100%" stopColor="#fbbf24" stopOpacity="0.0" />
                            </linearGradient>
                          </defs>

                          {/* Gradient Area Fill */}
                          <path d={areaD} fill="url(#chartGrad)" />

                          {/* Smooth Bezier Line */}
                          <path d={pathD} fill="none" stroke="#fbbf24" strokeWidth="2.5" strokeLinecap="round" />

                          {/* Data Spots */}
                          {coordinates.map((c, i) => (
                            <g
                              key={i}
                              className="cursor-pointer"
                              onMouseEnter={() => setHoveredChartIndex(i)}
                              onMouseLeave={() => setHoveredChartIndex(null)}
                            >
                              <circle
                                cx={c.x}
                                cy={c.y}
                                r={hoveredChartIndex === i ? 5 : 3.5}
                                fill="#ffffff"
                                stroke="#fbbf24"
                                strokeWidth="2"
                              />
                            </g>
                          ))}
                        </svg>
                      );
                    })()}

                    {/* Chart Tooltip */}
                    {hoveredChartIndex !== null && hourlyForecast[hoveredChartIndex] && (
                      <div className="absolute top-0 left-1/2 -translate-x-1/2 bg-neutral-900 border border-amber-400/50 px-2.5 py-1 rounded-lg text-center shadow-lg text-[10px]">
                        <span className="font-bold text-amber-300">
                          {formatTemp(hourlyForecast[hoveredChartIndex].temperature)}
                        </span>
                        <span className="text-white/70 ml-1.5">
                          • {hourlyForecast[hoveredChartIndex].hourLabel} ({hourlyForecast[hoveredChartIndex].rainProbability}% rain)
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Hour Labels */}
                  <div className="flex justify-between text-[10px] text-white/60 mt-1 px-1">
                    {hourlyForecast.slice(0, 6).map((h, i) => (
                      <span key={i}>{h.hourLabel}</span>
                    ))}
                  </div>
                </div>

                {/* Vertical Hourly List */}
                <div className="space-y-2">
                  <p className="text-xs font-bold text-white/90">Detailed 24-Hour Timeline</p>
                  {hourlyForecast.map((hour, idx) => (
                    <div
                      key={idx}
                      className="bg-white/12 backdrop-blur-md rounded-2xl p-3 border border-white/15 flex items-center justify-between text-xs hover:bg-white/18 transition"
                    >
                      <div className="w-16">
                        <p className="font-semibold text-white/95">{hour.hourLabel}</p>
                        <p className="text-[10px] text-white/60">{hour.condition}</p>
                      </div>

                      <div className="flex items-center space-x-2">
                        {renderWeatherIcon(hour.condition, hour.iconCode, 22)}
                        <span className="text-[11px] text-sky-200 font-medium">{hour.rainProbability}% rain</span>
                      </div>

                      <div className="text-right">
                        <p className="font-bold text-sm text-white">{formatTemp(hour.temperature)}</p>
                        <p className="text-[10px] text-white/60">{formatWind(hour.windSpeed)}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* TAB 3: 7-DAY FORECAST */}
            {activeTab === 'weekly' && (
              <div className="space-y-3 pt-1">
                <div className="bg-amber-400/20 backdrop-blur-md border border-amber-300/30 rounded-2xl p-3 flex items-start space-x-2.5 text-xs">
                  <Sparkles size={16} className="text-amber-300 shrink-0 mt-0.5" />
                  <p className="text-amber-100 text-[11px]">
                    Tap on any day below to expand and view detailed wind speeds, UV index, and sunrise/sunset times.
                  </p>
                </div>

                <div className="space-y-2.5">
                  {dailyForecast.map((day, idx) => {
                    const isExpanded = expandedDayIndex === idx;
                    return (
                      <div
                        key={idx}
                        className={`bg-white/14 backdrop-blur-xl rounded-2xl border transition-all duration-200 overflow-hidden ${
                          isExpanded ? 'border-amber-400/50 bg-white/20 ring-1 ring-amber-400/30' : 'border-white/15'
                        }`}
                      >
                        <div
                          onClick={() => setExpandedDayIndex(isExpanded ? null : idx)}
                          className="p-3.5 flex items-center justify-between cursor-pointer"
                        >
                          <div className="w-20">
                            <p className="font-bold text-xs text-white">{day.dayName}</p>
                            <p className="text-[10px] text-white/60">
                              {new Date(day.date).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}
                            </p>
                          </div>

                          <div className="flex items-center space-x-2 flex-1 px-2">
                            {renderWeatherIcon(day.condition, day.iconCode, 24)}
                            <div className="text-left">
                              <p className="text-[11px] font-medium text-white/90">{day.condition}</p>
                              {day.rainProbability > 0 && (
                                <p className="text-[10px] text-sky-300">{day.rainProbability}% rain</p>
                              )}
                            </div>
                          </div>

                          {/* Temperature Bar */}
                          <div className="flex items-center space-x-2 text-xs">
                            <span className="text-white/70 text-[11px]">{formatTemp(day.tempMin)}</span>
                            <div className="w-12 h-1.5 bg-white/20 rounded-full overflow-hidden">
                              <div className="w-full h-full bg-gradient-to-r from-sky-400 to-amber-400 rounded-full" />
                            </div>
                            <span className="font-bold text-white text-[11px]">{formatTemp(day.tempMax)}</span>
                            {isExpanded ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
                          </div>
                        </div>

                        {/* Expanded Details */}
                        {isExpanded && (
                          <div className="px-3.5 pb-3 pt-1 border-t border-white/10 grid grid-cols-4 gap-2 text-center text-xs">
                            <div className="bg-black/20 rounded-xl p-1.5">
                              <p className="text-[9px] text-white/60">Wind</p>
                              <p className="font-semibold text-[10px] mt-0.5">{formatWind(day.windSpeed)}</p>
                            </div>
                            <div className="bg-black/20 rounded-xl p-1.5">
                              <p className="text-[9px] text-white/60">UV Index</p>
                              <p className="font-semibold text-[10px] mt-0.5">{day.uvIndex} / 10</p>
                            </div>
                            <div className="bg-black/20 rounded-xl p-1.5">
                              <p className="text-[9px] text-white/60">Sunrise</p>
                              <p className="font-semibold text-[10px] mt-0.5">
                                {day.sunrise ? new Date(day.sunrise).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }) : '--:--'}
                              </p>
                            </div>
                            <div className="bg-black/20 rounded-xl p-1.5">
                              <p className="text-[9px] text-white/60">Sunset</p>
                              <p className="font-semibold text-[10px] mt-0.5">
                                {day.sunset ? new Date(day.sunset).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }) : '--:--'}
                              </p>
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* TAB 4: SAVED CITIES */}
            {activeTab === 'saved' && (
              <div className="space-y-3 pt-1">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-white/90">Favorite Locations</span>
                  <button
                    onClick={() => setIsAddCityModalOpen(true)}
                    className="flex items-center space-x-1 px-3 py-1 bg-white/20 hover:bg-white/30 rounded-full text-xs font-semibold text-white transition active:scale-95"
                  >
                    <Plus size={14} />
                    <span>Add City</span>
                  </button>
                </div>

                {savedCities.length === 0 ? (
                  <div className="text-center py-16 text-white/70 space-y-2">
                    <Heart size={36} className="mx-auto opacity-50" />
                    <p className="text-sm font-semibold">No Saved Cities</p>
                    <p className="text-xs text-white/50">Add favorite cities to quickly switch between them.</p>
                  </div>
                ) : (
                  <div className="space-y-2.5">
                    {savedCities.map((city, idx) => {
                      const isActive = currentWeather?.cityName.toLowerCase() === city.name.toLowerCase();
                      return (
                        <div
                          key={idx}
                          className={`bg-white/14 backdrop-blur-xl rounded-2xl p-3.5 border flex items-center justify-between transition cursor-pointer hover:bg-white/20 ${
                            isActive ? 'border-amber-400 bg-white/25 ring-1 ring-amber-400/50' : 'border-white/15'
                          }`}
                        >
                          <div
                            onClick={() => {
                              loadWeatherByCoords(city.latitude, city.longitude, city.name, city.country);
                              setActiveTab('home');
                            }}
                            className="flex items-center space-x-3 flex-1"
                          >
                            <div className="p-2 bg-white/20 rounded-full">
                              {renderWeatherIcon(city.condition || 'Clear', city.iconCode, 20)}
                            </div>
                            <div>
                              <div className="flex items-center space-x-1.5">
                                <p className="font-bold text-sm text-white">{city.name}</p>
                                {isActive && (
                                  <span className="text-[9px] bg-amber-400 text-slate-900 font-bold px-1.5 py-0.2 rounded-full">
                                    ACTIVE
                                  </span>
                                )}
                              </div>
                              <p className="text-[10px] text-white/60">{city.country || city.condition}</p>
                            </div>
                          </div>

                          <div className="flex items-center space-x-3">
                            {city.currentTemp !== undefined && (
                              <span className="font-extrabold text-base text-white">
                                {formatTemp(city.currentTemp)}
                              </span>
                            )}
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                removeCity(city.name);
                              }}
                              className="p-1.5 text-white/50 hover:text-rose-400 transition"
                              title="Remove city"
                            >
                              <Trash2 size={16} />
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            )}

            {/* TAB 5: SETTINGS */}
            {activeTab === 'settings' && (
              <div className="space-y-4 pt-1 text-xs">
                {/* Units */}
                <div className="bg-white/14 backdrop-blur-xl rounded-2xl p-4 border border-white/20 space-y-3">
                  <p className="font-bold text-amber-300 text-[11px] tracking-wider uppercase">Units of Measure</p>
                  
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-semibold text-white">Temperature Unit</p>
                      <p className="text-[10px] text-white/60">Choose between Celsius and Fahrenheit</p>
                    </div>
                    <div className="flex bg-black/25 rounded-xl p-0.5 border border-white/20">
                      <button
                        onClick={() => updateTempUnit('celsius')}
                        className={`px-3 py-1 rounded-lg font-bold text-xs transition ${
                          tempUnit === 'celsius' ? 'bg-amber-400 text-slate-900 shadow' : 'text-white/70'
                        }`}
                      >
                        °C
                      </button>
                      <button
                        onClick={() => updateTempUnit('fahrenheit')}
                        className={`px-3 py-1 rounded-lg font-bold text-xs transition ${
                          tempUnit === 'fahrenheit' ? 'bg-amber-400 text-slate-900 shadow' : 'text-white/70'
                        }`}
                      >
                        °F
                      </button>
                    </div>
                  </div>

                  <div className="w-full h-[1px] bg-white/10" />

                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-semibold text-white">Wind Speed Unit</p>
                      <p className="text-[10px] text-white/60">Choose km/h or meters per second</p>
                    </div>
                    <div className="flex bg-black/25 rounded-xl p-0.5 border border-white/20">
                      <button
                        onClick={() => updateWindUnit('kmh')}
                        className={`px-2.5 py-1 rounded-lg font-bold text-xs transition ${
                          windUnit === 'kmh' ? 'bg-amber-400 text-slate-900 shadow' : 'text-white/70'
                        }`}
                      >
                        km/h
                      </button>
                      <button
                        onClick={() => updateWindUnit('ms')}
                        className={`px-2.5 py-1 rounded-lg font-bold text-xs transition ${
                          windUnit === 'ms' ? 'bg-amber-400 text-slate-900 shadow' : 'text-white/70'
                        }`}
                      >
                        m/s
                      </button>
                    </div>
                  </div>
                </div>

                {/* Appearance Theme */}
                <div className="bg-white/14 backdrop-blur-xl rounded-2xl p-4 border border-white/20 space-y-2.5">
                  <p className="font-bold text-amber-300 text-[11px] tracking-wider uppercase">Appearance & Theme</p>
                  {(['system', 'light', 'dark'] as ThemePref[]).map((t) => (
                    <div
                      key={t}
                      onClick={() => updateThemePref(t)}
                      className={`flex items-center justify-between p-2.5 rounded-xl cursor-pointer transition ${
                        themePref === t ? 'bg-white/20 font-bold border border-white/30' : 'hover:bg-white/10'
                      }`}
                    >
                      <span className="capitalize">{t === 'system' ? 'System Default' : `${t} Theme`}</span>
                      {themePref === t && <Check size={16} className="text-amber-400" />}
                    </div>
                  ))}
                </div>

                {/* OpenWeatherMap API Key */}
                <div className="bg-white/14 backdrop-blur-xl rounded-2xl p-4 border border-white/20 space-y-2">
                  <p className="font-bold text-amber-300 text-[11px] tracking-wider uppercase">Weather API Provider</p>
                  <p className="text-[10px] text-white/70">
                    SkyPulse uses dual engines: Built-in Live Meteorological Service (active by default) and optional OpenWeatherMap key.
                  </p>
                  <button
                    onClick={() => setIsApiKeyModalOpen(true)}
                    className="w-full py-2 bg-white/20 hover:bg-white/30 rounded-xl font-semibold text-white text-xs border border-white/20 transition"
                  >
                    {owmApiKey ? 'Manage OpenWeatherMap API Key' : 'Configure Custom API Key'}
                  </button>
                </div>

                {/* About Application */}
                <div className="bg-white/10 backdrop-blur-xl rounded-2xl p-4 border border-white/20 space-y-2 text-[11px] text-white/80">
                  <div className="flex items-center space-x-2 font-bold text-white text-xs">
                    <Sparkles size={16} className="text-amber-400" />
                    <span>SkyPulse Weather v1.0.0</span>
                  </div>
                  <p>
                    Engineered with <strong>Flutter 3.35</strong>, <strong>Material 3</strong>, <strong>Provider</strong>, <strong>fl_chart</strong>, and sound null safety.
                  </p>
                </div>
              </div>
            )}
          </div>

          {/* Android Material 3 Bottom Navigation Bar */}
          <div className="relative z-30 bg-neutral-950/85 backdrop-blur-2xl border-t border-white/10 px-3 py-2 flex items-center justify-around">
            <button
              onClick={() => setActiveTab('home')}
              className={`flex flex-col items-center py-1 px-3 rounded-2xl transition ${
                activeTab === 'home' ? 'text-amber-400 font-bold bg-white/10' : 'text-white/60 hover:text-white'
              }`}
            >
              <Sun size={20} className={activeTab === 'home' ? 'fill-amber-400/20' : ''} />
              <span className="text-[10px] mt-0.5">Home</span>
            </button>

            <button
              onClick={() => setActiveTab('hourly')}
              className={`flex flex-col items-center py-1 px-3 rounded-2xl transition ${
                activeTab === 'hourly' ? 'text-amber-400 font-bold bg-white/10' : 'text-white/60 hover:text-white'
              }`}
            >
              <Clock size={20} />
              <span className="text-[10px] mt-0.5">Hourly</span>
            </button>

            <button
              onClick={() => setActiveTab('weekly')}
              className={`flex flex-col items-center py-1 px-3 rounded-2xl transition ${
                activeTab === 'weekly' ? 'text-amber-400 font-bold bg-white/10' : 'text-white/60 hover:text-white'
              }`}
            >
              <Calendar size={20} />
              <span className="text-[10px] mt-0.5">7-Day</span>
            </button>

            <button
              onClick={() => setActiveTab('saved')}
              className={`flex flex-col items-center py-1 px-3 rounded-2xl transition ${
                activeTab === 'saved' ? 'text-amber-400 font-bold bg-white/10' : 'text-white/60 hover:text-white'
              }`}
            >
              <Heart size={20} className={activeTab === 'saved' ? 'fill-amber-400/20' : ''} />
              <span className="text-[10px] mt-0.5">Saved</span>
            </button>
          </div>

          {/* Android Home Gesture Pill */}
          <div className="relative z-30 pb-2 pt-1 flex justify-center bg-neutral-950/85">
            <div className="w-28 h-1 bg-white/40 rounded-full" />
          </div>

          {/* Add City Modal */}
          {isAddCityModalOpen && (
            <div className="absolute inset-0 bg-black/70 backdrop-blur-md z-50 flex items-center justify-center p-4 animate-fade-in">
              <div className="bg-neutral-900 border border-white/20 rounded-3xl p-5 w-full max-w-[320px] shadow-2xl space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-bold text-sm">Add Favorite City</h3>
                  <button onClick={() => setIsAddCityModalOpen(false)} className="text-white/60 hover:text-white">
                    <X size={18} />
                  </button>
                </div>
                <input
                  type="text"
                  placeholder="Type city name (e.g. Paris)..."
                  value={newCityInput}
                  onChange={(e) => handleAddCitySearchChange(e.target.value)}
                  className="w-full bg-white/10 border border-white/20 rounded-xl px-3 py-2 text-xs text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-amber-400"
                  autoFocus
                />

                <div className="max-h-48 overflow-y-auto space-y-1">
                  {addCitySuggestions.map((c, i) => (
                    <div
                      key={i}
                      onClick={() => handleConfirmAddCity(c)}
                      className="p-2 hover:bg-white/10 rounded-xl cursor-pointer text-xs flex items-center justify-between transition"
                    >
                      <div>
                        <p className="font-semibold">{c.name}</p>
                        <p className="text-[10px] text-white/50">{[c.state, c.country].filter(Boolean).join(', ')}</p>
                      </div>
                      <Plus size={14} className="text-amber-400" />
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* API Key Modal */}
          {isApiKeyModalOpen && (
            <div className="absolute inset-0 bg-black/70 backdrop-blur-md z-50 flex items-center justify-center p-4 animate-fade-in">
              <div className="bg-neutral-900 border border-white/20 rounded-3xl p-5 w-full max-w-[320px] shadow-2xl space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-bold text-sm">OpenWeatherMap API Key</h3>
                  <button onClick={() => setIsApiKeyModalOpen(false)} className="text-white/60 hover:text-white">
                    <X size={18} />
                  </button>
                </div>
                <p className="text-[11px] text-white/70">
                  Enter your key from openweathermap.org. Leave empty to use the built-in live meteorological engine.
                </p>
                <input
                  type="text"
                  placeholder="Enter 32-character key..."
                  value={apiKeyInput}
                  onChange={(e) => setApiKeyInput(e.target.value)}
                  className="w-full bg-white/10 border border-white/20 rounded-xl px-3 py-2 text-xs text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-amber-400 font-mono"
                />
                <div className="flex justify-end space-x-2">
                  <button
                    onClick={() => setIsApiKeyModalOpen(false)}
                    className="px-3 py-1.5 rounded-xl text-xs text-white/70 hover:text-white"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={saveApiKey}
                    className="px-4 py-1.5 rounded-xl text-xs font-bold bg-amber-400 text-slate-900 hover:bg-amber-300 transition"
                  >
                    Save Key
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
