import { WeatherData, HourlyForecastItem, DailyForecastItem, SavedCity } from '../types/weather';

export class LiveWeatherService {
  private static mapWmoCode(code: number, isDay = true): { condition: string; description: string; iconCode: string } {
    const s = isDay ? 'd' : 'n';
    if (code === 0) return { condition: 'Clear', description: 'Clear sky', iconCode: `01${s}` };
    if (code === 1 || code === 2) return { condition: 'Clouds', description: 'Partly cloudy', iconCode: `02${s}` };
    if (code === 3) return { condition: 'Clouds', description: 'Overcast', iconCode: `04${s}` };
    if (code === 45 || code === 48) return { condition: 'Fog', description: 'Foggy', iconCode: `50${s}` };
    if (code >= 51 && code <= 55) return { condition: 'Drizzle', description: 'Light drizzle', iconCode: `09${s}` };
    if (code >= 61 && code <= 67) return { condition: 'Rain', description: 'Rain showers', iconCode: `10${s}` };
    if (code >= 71 && code <= 77) return { condition: 'Snow', description: 'Snowfall', iconCode: `13${s}` };
    if (code >= 80 && code <= 82) return { condition: 'Rain', description: 'Heavy showers', iconCode: `09${s}` };
    if (code >= 85 && code <= 86) return { condition: 'Snow', description: 'Snow showers', iconCode: `13${s}` };
    if (code >= 95 && code <= 99) return { condition: 'Thunderstorm', description: 'Thunderstorm', iconCode: `11${s}` };
    return { condition: 'Clear', description: 'Clear sky', iconCode: `01${s}` };
  }

  static async searchCities(query: string): Promise<SavedCity[]> {
    const clean = query.trim();
    if (clean.length < 2) return [];

    try {
      const res = await fetch(
        `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(clean)}&count=8&language=en&format=json`
      );
      if (!res.ok) return [];
      const data = await res.json();
      const results = data.results || [];
      return results.map((r: any) => ({
        name: r.name,
        country: r.country_code ? r.country_code.toUpperCase() : r.country || '',
        state: r.admin1,
        latitude: r.latitude,
        longitude: r.longitude,
      }));
    } catch {
      return [];
    }
  }

  static async fetchWeather(lat: number, lon: number, cityName?: string, countryName?: string, owmApiKey?: string): Promise<{
    current: WeatherData;
    hourly: HourlyForecastItem[];
    daily: DailyForecastItem[];
  }> {
    // If user provided an OpenWeatherMap API key, try that first
    if (owmApiKey && owmApiKey.trim().length > 10) {
      try {
        const curRes = await fetch(
          `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${owmApiKey.trim()}&units=metric`
        );
        if (curRes.ok) {
          const curData = await curRes.json();
          const fRes = await fetch(
            `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&appid=${owmApiKey.trim()}&units=metric`
          );
          const fData = fRes.ok ? await fRes.json() : null;

          const weatherList = curData.weather || [];
          const first = weatherList[0] || {};
          const isNight = first.icon ? first.icon.endsWith('n') : false;

          const current: WeatherData = {
            cityName: curData.name || cityName || 'Local Area',
            country: curData.sys?.country || countryName || '',
            latitude: lat,
            longitude: lon,
            temperature: curData.main?.temp ?? 20,
            feelsLike: curData.main?.feels_like ?? curData.main?.temp ?? 20,
            tempMin: curData.main?.temp_min ?? 15,
            tempMax: curData.main?.temp_max ?? 25,
            humidity: curData.main?.humidity ?? 50,
            windSpeed: curData.wind?.speed ?? 3,
            windDegree: curData.wind?.deg ?? 0,
            pressure: curData.main?.pressure ?? 1013,
            visibilityKm: (curData.visibility ?? 10000) / 1000,
            condition: first.main || 'Clear',
            description: first.description || 'Clear sky',
            iconCode: first.icon || '01d',
            isNight,
            dateTime: new Date(curData.dt * 1000).toISOString(),
            sunrise: new Date((curData.sys?.sunrise || 0) * 1000).toISOString(),
            sunset: new Date((curData.sys?.sunset || 0) * 1000).toISOString(),
            uvIndex: 5,
            cloudiness: curData.clouds?.all ?? 0,
          };

          const hourly: HourlyForecastItem[] = [];
          if (fData && fData.list) {
            for (const item of fData.list.slice(0, 10)) {
              const itemW = item.weather?.[0] || {};
              const dateObj = new Date(item.dt * 1000);
              hourly.push({
                time: dateObj.toISOString(),
                hourLabel: dateObj.toLocaleTimeString([], { hour: 'numeric' }),
                temperature: item.main?.temp ?? 20,
                feelsLike: item.main?.feels_like ?? 20,
                condition: itemW.main || 'Clear',
                description: itemW.description || '',
                iconCode: itemW.icon || '01d',
                rainProbability: Math.round((item.pop || 0) * 100),
                windSpeed: item.wind?.speed ?? 3,
                humidity: item.main?.humidity ?? 50,
              });
            }
          }

          // Also get 7-day from open-meteo for completeness
          const daily = await this.fetchDailyOnly(lat, lon);
          return { current, hourly, daily };
        }
      } catch {
        // Fallback to open-meteo
      }
    }

    // Direct High-Reliability Open-Meteo API
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m&hourly=temperature_2m,apparent_temperature,precipitation_probability,weather_code,wind_speed_10m,relative_humidity_2m&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,uv_index_max,sunrise,sunset&forecast_hours=24&timezone=auto`;
    const res = await fetch(url);
    if (!res.ok) throw new Error('Failed to retrieve live weather data');
    const data = await res.json();

    const cur = data.current || {};
    const d = data.daily || {};
    const h = data.hourly || {};

    const isDay = cur.is_day === 1;
    const wCode = cur.weather_code ?? 0;
    const cond = this.mapWmoCode(wCode, isDay);

    const temp = cur.temperature_2m ?? 20;
    const maxT = d.temperature_2m_max?.[0] ?? temp + 3;
    const minT = d.temperature_2m_min?.[0] ?? temp - 3;

    const current: WeatherData = {
      cityName: cityName || 'Local Weather',
      country: countryName || '',
      latitude: lat,
      longitude: lon,
      temperature: temp,
      feelsLike: cur.apparent_temperature ?? temp,
      tempMin: minT,
      tempMax: maxT,
      humidity: cur.relative_humidity_2m ?? 50,
      windSpeed: (cur.wind_speed_10m ?? 10) / 3.6, // convert km/h to m/s
      windDegree: cur.wind_direction_10m ?? 0,
      pressure: Math.round(cur.surface_pressure ?? 1013),
      visibilityKm: 10,
      condition: cond.condition,
      description: cond.description,
      iconCode: cond.iconCode,
      isNight: !isDay,
      dateTime: new Date().toISOString(),
      sunrise: d.sunrise?.[0] || new Date().toISOString(),
      sunset: d.sunset?.[0] || new Date().toISOString(),
      uvIndex: Math.round(d.uv_index_max?.[0] ?? 5),
      cloudiness: 20,
    };

    // Hourly
    const hourly: HourlyForecastItem[] = [];
    const hTimes = h.time || [];
    const hTemps = h.temperature_2m || [];
    const hFeels = h.apparent_temperature || [];
    const hPops = h.precipitation_probability || [];
    const hCodes = h.weather_code || [];
    const hWinds = h.wind_speed_10m || [];
    const hHumids = h.relative_humidity_2m || [];

    for (let i = 0; i < Math.min(hTimes.length, 24); i++) {
      const dt = new Date(hTimes[i]);
      const hour = dt.getHours();
      const isD = hour >= 6 && hour < 19;
      const parsed = this.mapWmoCode(hCodes[i] ?? 0, isD);

      hourly.push({
        time: hTimes[i],
        hourLabel: i === 0 ? 'Now' : dt.toLocaleTimeString([], { hour: 'numeric' }),
        temperature: hTemps[i] ?? 20,
        feelsLike: hFeels[i] ?? 20,
        condition: parsed.condition,
        description: parsed.description,
        iconCode: parsed.iconCode,
        rainProbability: Math.round(hPops[i] ?? 0),
        windSpeed: (hWinds[i] ?? 10) / 3.6,
        humidity: Math.round(hHumids[i] ?? 50),
      });
    }

    // Daily
    const weekdayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const daily: DailyForecastItem[] = [];
    const dTimes = d.time || [];
    const dMax = d.temperature_2m_max || [];
    const dMin = d.temperature_2m_min || [];
    const dCodes = d.weather_code || [];
    const dPops = d.precipitation_probability_max || [];
    const dWinds = d.wind_speed_10m_max || [];
    const dUvs = d.uv_index_max || [];
    const dSunrises = d.sunrise || [];
    const dSunsets = d.sunset || [];

    for (let i = 0; i < Math.min(dTimes.length, 7); i++) {
      const dt = new Date(dTimes[i]);
      const parsed = this.mapWmoCode(dCodes[i] ?? 0, true);
      const dayName = i === 0 ? 'Today' : i === 1 ? 'Tomorrow' : weekdayNames[dt.getDay()];

      daily.push({
        date: dTimes[i],
        dayName,
        tempMin: dMin[i] ?? 15,
        tempMax: dMax[i] ?? 24,
        tempDay: ((dMin[i] ?? 15) + (dMax[i] ?? 24)) / 2,
        condition: parsed.condition,
        description: parsed.description,
        iconCode: parsed.iconCode,
        rainProbability: Math.round(dPops[i] ?? 0),
        windSpeed: (dWinds[i] ?? 10) / 3.6,
        uvIndex: Math.round(dUvs[i] ?? 5),
        sunrise: dSunrises[i] || '',
        sunset: dSunsets[i] || '',
      });
    }

    return { current, hourly, daily };
  }

  private static async fetchDailyOnly(lat: number, lon: number): Promise<DailyForecastItem[]> {
    try {
      const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,uv_index_max,sunrise,sunset&timezone=auto`;
      const res = await fetch(url);
      if (!res.ok) return [];
      const data = await res.json();
      const d = data.daily || {};
      const weekdayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      const daily: DailyForecastItem[] = [];

      for (let i = 0; i < Math.min(d.time?.length || 0, 7); i++) {
        const dt = new Date(d.time[i]);
        const parsed = this.mapWmoCode(d.weather_code[i] ?? 0, true);
        daily.push({
          date: d.time[i],
          dayName: i === 0 ? 'Today' : i === 1 ? 'Tomorrow' : weekdayNames[dt.getDay()],
          tempMin: d.temperature_2m_min[i] ?? 15,
          tempMax: d.temperature_2m_max[i] ?? 24,
          tempDay: ((d.temperature_2m_min[i] ?? 15) + (d.temperature_2m_max[i] ?? 24)) / 2,
          condition: parsed.condition,
          description: parsed.description,
          iconCode: parsed.iconCode,
          rainProbability: Math.round(d.precipitation_probability_max[i] ?? 0),
          windSpeed: (d.wind_speed_10m_max[i] ?? 10) / 3.6,
          uvIndex: Math.round(d.uv_index_max[i] ?? 5),
          sunrise: d.sunrise[i] || '',
          sunset: d.sunset[i] || '',
        });
      }
      return daily;
    } catch {
      return [];
    }
  }
}
