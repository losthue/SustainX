const { sequelize } = require('../config/db');

// Open-Meteo API (free, no key)
const WEATHER_API = 'https://api.open-meteo.com/v1/forecast';
const DEFAULT_LAT = -20.1654;
const DEFAULT_LON = 57.5045;

// OpenRouter AI
const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';

// Base conversion rates (fallback)
const BASE_RATES = { yellow: 1.0, green: 0.5 };

function getWeatherDescription(code) {
    if (code === 0) return 'Clear Sky';
    if (code <= 1) return 'Mainly Clear';
    if (code <= 2) return 'Partly Cloudy';
    if (code <= 3) return 'Overcast';
    if (code <= 48) return 'Foggy';
    if (code <= 55) return 'Light Drizzle';
    if (code <= 61) return 'Light Rain';
    if (code <= 63) return 'Moderate Rain';
    if (code <= 65) return 'Heavy Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Showers';
    if (code === 95) return 'Thunderstorm';
    if (code <= 99) return 'Thunderstorm with Hail';
    return 'Unknown';
}

function getWeatherIcon(code) {
    if (code === 0) return 'clear';
    if (code <= 2) return 'partly_cloudy';
    if (code <= 3) return 'cloudy';
    if (code <= 48) return 'fog';
    if (code <= 67) return 'rain';
    if (code <= 77) return 'snow';
    if (code <= 82) return 'showers';
    return 'thunderstorm';
}

class WeatherService {

    // ── Fetch raw weather from Open-Meteo ────────────────────────────────
    static async _fetchWeather(lat = DEFAULT_LAT, lon = DEFAULT_LON) {
        const url = `${WEATHER_API}?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code,cloud_cover&daily=weather_code,temperature_2m_max,temperature_2m_min,sunshine_duration,precipitation_sum&timezone=auto&forecast_days=7`;

        const response = await fetch(url);
        if (!response.ok) throw new Error(`Weather API error: ${response.status}`);
        return response.json();
    }

    // ── Ask AI for rate recommendations ──────────────────────────────────
    static async _getAIRates(weatherData) {
        const apiKey = process.env.OPENROUTER_API_KEY;
        if (!apiKey) {
            console.warn('No OPENROUTER_API_KEY — using rule-based fallback');
            return null;
        }

        const current = weatherData.current;
        const daily = weatherData.daily;

        // Build a concise weather summary for the AI
        const forecastSummary = (daily.time || []).map((date, i) => ({
            date,
            weather: getWeatherDescription(daily.weather_code[i]),
            temp_max: daily.temperature_2m_max[i],
            temp_min: daily.temperature_2m_min[i],
            sunshine_hrs: ((daily.sunshine_duration?.[i] || 0) / 3600).toFixed(1),
            precipitation_mm: daily.precipitation_sum?.[i] || 0,
        }));

        const prompt = `You are a solar energy economist for a community coin system in Mauritius.

CONTEXT:
- Users earn Yellow coins (badge, rate base: 1.0× per kWh surplus) and Green coins (tradeable, rate base: 0.5× per kWh surplus)
- When solar production is RARER (cloudy/rainy), coins should be worth MORE (higher multiplier) to reward those who still produce
- When solar is ABUNDANT (clear skies), rates stay closer to base
- Multiplier range: 0.8× to 2.5× (never go outside this range)

CURRENT WEATHER:
- Temperature: ${current.temperature_2m}°C
- Humidity: ${current.relative_humidity_2m}%
- Wind: ${current.wind_speed_10m} km/h
- Cloud cover: ${current.cloud_cover}%
- Condition: ${getWeatherDescription(current.weather_code)}

7-DAY FORECAST:
${JSON.stringify(forecastSummary, null, 2)}

TASK: Return a JSON object with adjusted coin rates. Consider:
1. Cloud cover reduces solar panel output
2. Rain/storms severely reduce production
3. High sunshine hours = abundant energy = lower multiplier
4. Factor in temperature (extreme heat reduces panel efficiency)

Return ONLY valid JSON, no markdown, no explanation:
{
  "current_yellow_rate": <number>,
  "current_green_rate": <number>,
  "reasoning": "<one line explanation>",
  "forecast": [
    {"date": "<YYYY-MM-DD>", "yellow_rate": <number>, "green_rate": <number>},
    ...for each of the 7 days
  ]
}`;

        try {
            const response = await fetch(OPENROUTER_URL, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${apiKey}`,
                    'Content-Type': 'application/json',
                    'HTTP-Referer': 'https://sustainx.app',
                    'X-Title': 'SustainX Energy Coin System',
                },
                body: JSON.stringify({
                    model: 'google/gemini-2.0-flash-001',
                    messages: [{ role: 'user', content: prompt }],
                    temperature: 0.3,
                    max_tokens: 800,
                }),
            });

            if (!response.ok) {
                const errText = await response.text();
                console.error('OpenRouter error:', response.status, errText);
                return null;
            }

            const result = await response.json();
            const content = result.choices?.[0]?.message?.content || '';

            // Extract JSON from response (handle potential markdown wrapping)
            let jsonStr = content.trim();
            if (jsonStr.startsWith('```')) {
                jsonStr = jsonStr.replace(/```json?\n?/g, '').replace(/```/g, '').trim();
            }

            const parsed = JSON.parse(jsonStr);
            return parsed;
        } catch (err) {
            console.error('AI rate calculation error:', err.message);
            return null;
        }
    }

    // ── Rule-based fallback ──────────────────────────────────────────────
    static _fallbackRates(weatherData) {
        const daily = weatherData.daily;

        function getMultiplier(code, sunshineSeconds) {
            const sunHours = (sunshineSeconds || 0) / 3600;
            let m = 1.0;
            // Weather-based
            if (code <= 0) m = 1.0;
            else if (code <= 1) m = 1.15;
            else if (code <= 2) m = 1.3;
            else if (code <= 3) m = 1.5;
            else if (code <= 48) m = 1.7;
            else if (code <= 67) m = 1.9;
            else m = 2.1;
            // Sunshine adjustment
            if (sunHours < 4) m += 0.2;
            else if (sunHours > 8) m -= 0.1;
            return Math.max(0.8, Math.min(2.5, m));
        }

        const currentCode = weatherData.current.weather_code;
        const currentMultiplier = getMultiplier(currentCode, null);

        return {
            current_yellow_rate: +(BASE_RATES.yellow * currentMultiplier).toFixed(2),
            current_green_rate: +(BASE_RATES.green * currentMultiplier).toFixed(2),
            reasoning: `Rule-based: ${getWeatherDescription(currentCode)} conditions`,
            forecast: (daily.time || []).map((date, i) => {
                const m = getMultiplier(daily.weather_code[i], daily.sunshine_duration?.[i]);
                return {
                    date,
                    yellow_rate: +(BASE_RATES.yellow * m).toFixed(2),
                    green_rate: +(BASE_RATES.green * m).toFixed(2),
                };
            }),
        };
    }

    // ── Main: Get weather + AI-calculated rates ─────────────────────────
    static async getWeatherAndRates(lat = DEFAULT_LAT, lon = DEFAULT_LON) {
        const weatherData = await WeatherService._fetchWeather(lat, lon);

        // Try AI first, fall back to rules
        let aiRates = await WeatherService._getAIRates(weatherData);
        if (!aiRates) {
            aiRates = WeatherService._fallbackRates(weatherData);
        }

        // Current weather
        const current = {
            temperature: weatherData.current.temperature_2m,
            humidity: weatherData.current.relative_humidity_2m,
            wind_speed: weatherData.current.wind_speed_10m,
            cloud_cover: weatherData.current.cloud_cover,
            weather_code: weatherData.current.weather_code,
            weather_description: getWeatherDescription(weatherData.current.weather_code),
            weather_icon: getWeatherIcon(weatherData.current.weather_code),
        };

        // Current adjusted rates from AI
        const currentRates = {
            yellow: aiRates.current_yellow_rate,
            green: aiRates.current_green_rate,
        };

        // 7-day forecast with AI rates
        const forecast = (weatherData.daily.time || []).map((date, i) => {
            const code = weatherData.daily.weather_code[i];
            const aiDay = aiRates.forecast?.find(f => f.date === date) || {};
            return {
                date,
                temp_max: weatherData.daily.temperature_2m_max[i],
                temp_min: weatherData.daily.temperature_2m_min[i],
                sunshine_hours: +((weatherData.daily.sunshine_duration?.[i] || 0) / 3600).toFixed(1),
                precipitation_mm: weatherData.daily.precipitation_sum?.[i] || 0,
                weather_code: code,
                weather_description: getWeatherDescription(code),
                weather_icon: getWeatherIcon(code),
                yellow_rate: aiDay.yellow_rate ?? currentRates.yellow,
                green_rate: aiDay.green_rate ?? currentRates.green,
            };
        });

        return {
            current,
            current_rates: currentRates,
            base_rates: BASE_RATES,
            ai_reasoning: aiRates.reasoning || '',
            forecast,
            solar_forecast: aiRates.reasoning || 'AI-adjusted rates based on weather',
        };
    }

    // ── Get current dynamic rates (for energy recording) ────────────────
    static async getCurrentRates() {
        try {
            const data = await WeatherService.getWeatherAndRates();
            return {
                yellow: data.current_rates.yellow,
                green: data.current_rates.green,
                red: 1.5, // Red rate stays fixed (penalty)
                weather: data.current.weather_description,
                ai_reasoning: data.ai_reasoning,
            };
        } catch (err) {
            console.error('Failed to get dynamic rates, using defaults:', err.message);
            return {
                yellow: BASE_RATES.yellow,
                green: BASE_RATES.green,
                red: 1.5,
                weather: 'Unknown',
                ai_reasoning: 'Fallback to base rates',
            };
        }
    }
}

module.exports = WeatherService;
