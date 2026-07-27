import { useState, useCallback } from 'react';
import TerminalShell from '../../components/TerminalShell';

const CACHE = {};

async function fetchWeather(lat, lon) {
  const key = `${lat},${lon}`;
  if (CACHE[key]) return CACHE[key];
  const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min&timezone=auto`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const data = await res.json();
  CACHE[key] = data;
  return data;
}

const WEATHER_CODES = {
  0: '☀️ Clear sky', 1: '🌤 Mainly clear', 2: '⛅ Partly cloudy', 3: '☁️ Overcast',
  45: '🌫️ Foggy', 48: '🌫️ Rime fog',
  51: '🌦 Light drizzle', 53: '🌦 Moderate drizzle', 55: '🌦 Dense drizzle',
  56: '🌧 Light freezing drizzle', 57: '🌧 Dense freezing drizzle',
  61: '🌦 Slight rain', 63: '🌧 Moderate rain', 65: '🌧 Heavy rain',
  66: '🌧 Light freezing rain', 67: '🌧 Heavy freezing rain',
  71: '🌨 Slight snow', 73: '🌨 Moderate snow', 75: '🌨 Heavy snow',
  77: '❄️ Snow grains',
  80: '🌦 Slight rain showers', 81: '🌧 Moderate rain showers', 82: '🌧 Violent rain showers',
  85: '🌨 Slight snow showers', 86: '🌨 Heavy snow showers',
  95: '⛈️ Thunderstorm', 96: '⛈️ Thunderstorm with slight hail', 99: '⛈️ Thunderstorm with heavy hail',
};

function weatherDesc(code) {
  return WEATHER_CODES[code] || `Code ${code}`;
}

export default function Weather() {
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState('idle');
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);

  const lookup = useCallback(async () => {
    if (!query.trim()) return;
    setStatus('loading');
    setError(null);
    setData(null);
    try {
      const geoUrl = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(query.trim())}&count=1&language=en&format=json`;
      const geoRes = await fetch(geoUrl);
      if (!geoRes.ok) throw new Error('Location not found');
      const geoData = await geoRes.json();
      if (!geoData.results || geoData.results.length === 0) throw new Error(`Location "${query}" not found`);
      const { latitude, longitude, name, country, admin1 } = geoData.results[0];
      const weather = await fetchWeather(latitude, longitude);
      setData({ location: `${name}${admin1 ? ', ' + admin1 : ''}${country ? ', ' + country : ''}`, weather });
      setStatus('done');
    } catch (e) {
      setError(e.message);
      setStatus('error');
    }
  }, [query]);

  return (
    <TerminalShell
      title="weather — Weather"
      subtitle="_weather.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Powered by Open-Meteo (free, no API key). Your location is sent to Open-Meteo's geocoding and forecast APIs."
    >
      <div className="uk-row">
        <div className="uk-field" style={{ flex: 2 }}>
          <label>City or location</label>
          <input className="uk-input" value={query} placeholder="London, Tokyo, San Francisco…" onChange={(e) => setQuery(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && lookup()} />
        </div>
      </div>
      <button className="uk-btn" onClick={lookup} disabled={status === 'loading'}>
        {status === 'loading' ? '⟳ Loading…' : '☀ Look up'}
      </button>

      <div className="uk-out-box">
        {status === 'loading' && <div className="uk-dim">Fetching weather data…</div>}
        {status === 'error' && <div className="uk-red">✖ {error}</div>}
        {data && (
          <>
            <div className="uk-line" style={{ fontWeight: 600, marginBottom: 8 }}>{data.location}</div>
            <div className="uk-line" style={{ fontSize: 28, color: '#3fb950' }}>
              {data.weather.current.temperature_2m}°C
            </div>
            <div className="uk-line uk-dim">
              Feels like {data.weather.current.apparent_temperature}°C · {weatherDesc(data.weather.current.weather_code)}
            </div>
            <div className="uk-line" style={{ marginTop: 6 }}>
              <span className="uk-dim">Humidity:</span> {data.weather.current.relative_humidity_2m}%{' '}
              <span className="uk-dim">Wind:</span> {data.weather.current.wind_speed_10m} km/h
            </div>
            <div className="uk-line uk-dim" style={{ marginTop: 6, fontSize: 11.5 }}>
              H: {data.weather.daily.temperature_2m_max[0]}°C{' '}
              L: {data.weather.daily.temperature_2m_min[0]}°C
            </div>
          </>
        )}
        {status === 'idle' && <div className="uk-dim">Enter a city name and press Look up.</div>}
      </div>
    </TerminalShell>
  );
}
