# Climatch — Product Specification (MVP)

## Goal
A simple yet distinctive weather app that highlights microclimate conditions and activity-specific insights.

## Scope
- Platforms: iOS and Android (Flutter)
- Regions: Global, initial focus on English locale
- Target users: Runners, walkers, casual commuters

## Functional Requirements (MVP)
1. Current Weather + 24h Forecast
   - Display: temperature, feels-like, condition, precipitation, humidity, wind, pressure, cloud cover.
   - Forecast: hourly for next 24h (chart + list).
   - Location: auto-detect via GPS and manual search; unit toggles (°C/°F, km/h/mph).

2. Microclimate Indicator (GPS-based)
   - Compute a local deviation vs. nearby station/baseline (e.g., warmer/cooler/windier than area average).
   - Present as a concise chip/badge with delta (e.g., “Slightly warmer (+1.5°C)”).

3. Activity-Specific Weather (e.g., Running, Walking)
   - Provide an activity “comfort score” (0–100) and short guidance (e.g., hydrate, wind caution).
   - Inputs: temperature/heat index, humidity, wind, precipitation probability/intensity, UV if available.

4. Push Notifications for Sudden Changes
   - Triggers (configurable):
     - Temperature drop/rise beyond threshold within 1–2 hours.
     - Rain starting soon; wind gusts exceeding threshold.
   - Quiet hours; per-activity relevance (optional in MVP).

5. Offline Mode (Cached Data)
   - Cache last successful fetch per location and show “Last updated”.
   - Use TTL (e.g., 30–60 min) and size limits; readable fallback when offline.

## Extra Features (Post-MVP)
- Outfit suggestion based on forecast and wind/precipitation.
- UV index and allergen/pollen index (region permitting).
- Light “mood/humor” weather summary.

## Data Sources
- OpenWeatherMap (One Call) for current + hourly forecast.
- Meteostat for nearby station observations (microclimate baseline/deltas).
- Optional user input (thumbs-up/down on comfort; stored locally or anonymized).

## Architecture
- Frontend (Flutter):
  - State mgmt: Riverpod or Provider.
  - Networking: Dio or http; JSON models with freezed/json_serializable.
  - Location: geolocator; Permissions handling.
  - Storage: Hive (offline cache) + shared_preferences (settings).
  - Notifications: Firebase Cloud Messaging (FCM) via firebase_messaging.
- Backend (choose one):
  - Option A: Node.js 20 + Express.
    - Endpoints: /weather?lat&lon, /microclimate?lat&lon, /alerts/subscribe.
    - Responsibilities: API key management, rate limiting, response normalization, microclimate calc, notification jobs.
  - Option B: Firebase Functions + Firestore/RTDB for subscriptions and schedules (Cloud Scheduler + Pub/Sub).
- Security: keep external API keys server-side; HTTPS; environment secrets.

## Microclimate Calculation v0
- Find nearest Meteostat stations within a radius (e.g., 10–20 km).
- Compare OWM current conditions with station observations to derive deltas (T, wind, humidity).
- Categorize: Slightly/Much Warmer or Cooler (±1–2°C, >2°C), Windier, More Humid; show top 1–2 signals.

## Activity Score v0
- Base 100; subtract penalties:
  - Heat index: −(weighted function above comfort band by temp+RH).
  - Wind: − based on speed/gust thresholds; headwind heuristics not in MVP.
  - Rain: − proportional to probability/intensity.
  - UV (if available): − above moderate levels unless evening.
- Output: score 0–100, 1–2 short tips.

## API Contract (Proposed)
- GET /weather?lat={lat}&lon={lon}
  - Returns: current, hourly[24], units, source timestamps.
- GET /microclimate?lat={lat}&lon={lon}
  - Returns: indicators[{type, delta, unit, confidence}], updated_at.
- POST /alerts/subscribe { token, lat, lon, thresholds, quiet_hours }
  - 200 on success; server stores minimal subscription.

## Data Model (App)
- Weather: { temp, feels_like, condition, precip_prob, precip_mm, humidity, wind_speed, wind_gust, pressure, clouds, uv (opt), ts }
- Hourly: [Weather] 24 items
- MicroclimateIndicator: { type: “temp|wind|humidity”, delta, unit, confidence }
- ActivityScore: { activity, score, tips[] }
- Settings: { units, activities[], notifications: { enabled, quiet_hours } }

## UX Outline
- Home: current card, 24h chart, microclimate chip, activity selector with score.
- Details: hourly list, UV card (if available), microclimate explanation link.
- Settings: units, notifications, activities, data sources, privacy.

## Non-Functional Requirements
- Performance: first meaningful paint < 2s on mid-tier devices; smooth scrolling 60fps target.
- Reliability: degrade gracefully offline; clear cache strategy; background fetch where supported.
- Accessibility: dynamic type, sufficient contrast, screen reader labels.
- Privacy: explicit location consent; approximate location supported; no personal data sale; minimal retention.
- Localization: English initially; Hungarian next.

## Notifications (MVP Rules)
- Temp change: |ΔT| ≥ 3°C within next 2h.
- Rain starting: PoP ≥ 60% in next hour; wind gust ≥ 12 m/s.
- Respect quiet hours and per-day max notifications (e.g., ≤ 3/day).

## Analytics & Monitoring
- Crash reporting (e.g., Firebase Crashlytics).
- Minimal telemetry: screen views, API error rates; opt-out toggle.

## Testing & Acceptance Criteria
- Current + 24h: displays accurate data for given coordinates; unit toggle updates UI instantly.
- Microclimate: shows indicator with delta when station data available; hides gracefully when not.
- Activity score: deterministic for given inputs; tips match thresholds.
- Push alerts: delivered for synthetic trigger scenarios; respects quiet hours and daily cap.
- Offline: shows last cached data when airplane mode enabled; “Last updated” timestamp visible.

## Milestones (Indicative)
- Week 1–2: Project setup, data models, current weather + 24h UI.
- Week 3: Microclimate v0, caching, settings.
- Week 4: Activity score, notifications MVP.
- Week 5: QA, polish, store assets.

## Open Questions
- Allergen data source per region? (e.g., Ambee, Tomorrow.io)
- Use Map tiles or city context for microclimate explanations?
- Which activities beyond running/walking for v1?
