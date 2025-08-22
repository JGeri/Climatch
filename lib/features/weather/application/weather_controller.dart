import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../hourly.dart';
import '../../../services/openweather_api.dart';
import '../../../core/utils/icon_mapper.dart';

class WeatherController extends ChangeNotifier {
  // Public state (read via getters)
  List<Hourly> _hourly = [];
  List<Hourly> _hourlyToday = [];
  List<Hourly> _hourlyTomorrow = [];
  int _tabIndex = 0;

  String? _cityName;
  String? _locationError;
  double? _lat;
  double? _lon;
  int? _tempC;
  String? _conditionText;
  String _iconAsset = IconMapper.fromCondition('sunny');
  int? _aqi;

  int? _sunriseSecUtc;
  int? _sunsetSecUtc;
  int? _dayLengthMin;
  int? _sunElapsedMin;
  int? _tzOffsetSec;
  int? _moonriseSecUtc;
  int? _moonsetSecUtc;

  // Cache
  static const String _cacheKey = 'weather_cache_v1';
  static const Duration _cacheTtl = Duration(minutes: 15);
  int? _cacheTsMs;
  bool _initialized = false;
  bool _loading = false;

  bool get loading => _loading;
  bool get initialized => _initialized;
  int get tabIndex => _tabIndex;
  List<Hourly> get hourly => _hourly;
  List<Hourly> get hourlyToday => _hourlyToday;
  List<Hourly> get hourlyTomorrow => _hourlyTomorrow;
  String? get cityName => _cityName;
  String? get locationError => _locationError;
  int? get tempC => _tempC;
  String? get conditionText => _conditionText;
  String get iconAsset => _iconAsset;
  int? get aqi => _aqi;
  int? get sunriseSecUtc => _sunriseSecUtc;
  int? get sunsetSecUtc => _sunsetSecUtc;
  int? get dayLengthMin => _dayLengthMin;
  int? get sunElapsedMin => _sunElapsedMin;
  int? get tzOffsetSec => _tzOffsetSec;
  int? get moonriseSecUtc => _moonriseSecUtc;
  int? get moonsetSecUtc => _moonsetSecUtc;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _loadCache();
    final now = DateTime.now().millisecondsSinceEpoch;
    final isStale =
        _cacheTsMs == null ||
        (now - (_cacheTsMs ?? 0)) > _cacheTtl.inMilliseconds;
    if (isStale) {
      unawaited(refreshAll());
    }
  }

  Future<void> refreshAll() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      if (_lat != null && _lon != null) {
        await Future.wait([
          _fetchWeather(_lat!, _lon!),
          _fetchHourly(_lat!, _lon!),
          _fetchAqi(_lat!, _lon!),
        ]);
        await _saveCache();
      } else {
        await _resolveCityFromGps();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void onTabChanged(int index) {
    _tabIndex = index;
    _hourly = index == 0 ? _hourlyToday : _hourlyTomorrow;
    notifyListeners();
  }

  Future<void> _resolveCityFromGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'Location services are disabled';
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _locationError = 'Location permission denied';
        notifyListeners();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      _lat = pos.latitude;
      _lon = pos.longitude;

      final places = await geocoding.placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
        localeIdentifier: 'hu_HU',
      );
      if (places.isNotEmpty) {
        final p = places.first;
        final name = p.locality?.isNotEmpty == true
            ? p.locality!
            : (p.subAdministrativeArea?.isNotEmpty == true
                  ? p.subAdministrativeArea!
                  : (p.administrativeArea?.isNotEmpty == true
                        ? p.administrativeArea!
                        : null));
        _cityName = name ?? 'Unknown';
      }

      await Future.wait([
        _fetchWeather(pos.latitude, pos.longitude),
        _fetchHourly(pos.latitude, pos.longitude),
        _fetchAqi(pos.latitude, pos.longitude),
      ]);
      await _saveCache();
    } catch (e) {
      _locationError = 'Location error';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final api = OpenWeatherApi.fromEnvironment();
      final data = await api.currentByCoords(
        lat,
        lon,
        units: 'metric',
        lang: 'hu',
      );
      final temp = (data['main']?['temp'] as num?)?.toDouble();
      final weatherList = (data['weather'] as List?) ?? const [];
      final first = weatherList.isNotEmpty
          ? weatherList.first as Map<String, dynamic>
          : const {};
      final desc = first['description']?.toString();
      final iconCode = first['icon']?.toString();

      final sys = (data['sys'] as Map?)?.cast<String, dynamic>();
      final sunriseSec = (sys?['sunrise'] as num?)?.toInt();
      final sunsetSec = (sys?['sunset'] as num?)?.toInt();
      int? dayLenMin;
      int? elapsedMin;
      if (sunriseSec != null && sunsetSec != null && sunsetSec > sunriseSec) {
        dayLenMin = ((sunsetSec - sunriseSec) / 60).round();
        final nowSecUtc = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
        final rawElapsed = ((nowSecUtc - sunriseSec) / 60).floor();
        elapsedMin = rawElapsed.clamp(0, dayLenMin);
      }

      _tempC = temp != null ? temp.round() : null;
      _conditionText = desc;
      _iconAsset = IconMapper.fromOwmIcon(iconCode);
      _sunriseSecUtc = sunriseSec;
      _sunsetSecUtc = sunsetSec;
      _dayLengthMin = dayLenMin;
      _sunElapsedMin = elapsedMin;
    } catch (_) {
      // ignore
    }
  }

  Future<void> _fetchHourly(double lat, double lon) async {
    try {
      final api = OpenWeatherApi.fromEnvironment();
      final data = await api.oneCall(
        lat,
        lon,
        units: 'metric',
        lang: 'hu',
        exclude: const ['minutely', 'alerts'],
      );
      final tzOffsetSec = (data['timezone_offset'] as num?)?.toInt() ?? 0;
      final List hours = (data['hourly'] as List?) ?? const [];
      final List daily = (data['daily'] as List?) ?? const [];

      final nowLocal = DateTime.now().toUtc().add(
        Duration(seconds: tzOffsetSec),
      );
      final tomorrowLocal = nowLocal.add(const Duration(days: 1));

      final List<Hourly> today = [];
      final List<Hourly> tomorrow = [];

      for (final h in hours) {
        final dtSec = (h['dt'] as num?)?.toInt();
        final temp = (h['temp'] as num?)?.toDouble();
        final weatherList = (h['weather'] as List?) ?? const [];
        final first = weatherList.isNotEmpty
            ? weatherList.first as Map<String, dynamic>
            : const {};
        final iconCode = first['icon']?.toString();
        if (dtSec == null || temp == null) continue;

        final local = DateTime.fromMillisecondsSinceEpoch(
          dtSec * 1000,
          isUtc: true,
        ).add(Duration(seconds: tzOffsetSec));
        final isToday =
            local.year == nowLocal.year &&
            local.month == nowLocal.month &&
            local.day == nowLocal.day;
        final isTomorrow =
            local.year == tomorrowLocal.year &&
            local.month == tomorrowLocal.month &&
            local.day == tomorrowLocal.day;

        if (isToday && local.hour >= nowLocal.hour) {
          today.add(
            Hourly(
              hour: local.hour,
              temp: temp.round(),
              condition: iconCode ?? '01d',
            ),
          );
        }
        if (isTomorrow) {
          tomorrow.add(
            Hourly(
              hour: local.hour,
              temp: temp.round(),
              condition: iconCode ?? '01n',
            ),
          );
        }
      }

      final zeroOfTomorrow = tomorrow.where((e) => e.hour == 0).toList();
      if (zeroOfTomorrow.isNotEmpty &&
          (today.isEmpty || today.last.hour != 0)) {
        today.add(zeroOfTomorrow.first);
      }

      int? tRiseUtc;
      int? tSetUtc;
      if (daily.isNotEmpty) {
        for (int i = 0; i < daily.length; i++) {
          final m = (daily[i] as Map).cast<String, dynamic>();
          final dt = (m['dt'] as num?)?.toInt();
          if (dt == null) continue;
          final local = DateTime.fromMillisecondsSinceEpoch(
            dt * 1000,
            isUtc: true,
          ).add(Duration(seconds: tzOffsetSec));
          if (local.year == nowLocal.year &&
              local.month == nowLocal.month &&
              local.day == nowLocal.day) {
            tRiseUtc = _nullIfZero(m['moonrise'] as num?);
            tSetUtc = _nullIfZero(m['moonset'] as num?);
            break;
          }
        }
        if (tRiseUtc == null && tSetUtc == null) {
          final first = (daily.first as Map).cast<String, dynamic>();
          tRiseUtc = _nullIfZero(first['moonrise'] as num?);
          tSetUtc = _nullIfZero(first['moonset'] as num?);
        }
      }

      _hourlyToday = today;
      _hourlyTomorrow = (tomorrow..sort((a, b) => a.hour.compareTo(b.hour)));
      _hourly = _tabIndex == 0 ? _hourlyToday : _hourlyTomorrow;
      _tzOffsetSec = tzOffsetSec;
      _moonriseSecUtc = tRiseUtc;
      _moonsetSecUtc = tSetUtc;
    } catch (_) {
      // ignore
    }
  }

  Future<void> _fetchAqi(double lat, double lon) async {
    try {
      final uri =
          Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
            'latitude': lat.toString(),
            'longitude': lon.toString(),
            'hourly': 'us_aqi',
            'timezone': 'auto',
          });
      final res = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      if (res.statusCode < 200 || res.statusCode >= 300) return;
      final data = json.decode(res.body);
      final hourly = data['hourly'] as Map<String, dynamic>?;
      if (hourly == null) return;
      final times = (hourly['time'] as List?)?.cast<String>() ?? const [];
      final values = (hourly['us_aqi'] as List?)?.cast<num>() ?? const [];
      if (times.isEmpty || values.isEmpty) return;
      final now = DateTime.now();
      int bestIdx = 0;
      Duration bestDiff = const Duration(days: 9999);
      for (int i = 0; i < times.length && i < values.length; i++) {
        final tStr = times[i];
        try {
          final t = DateTime.parse(tStr);
          final diff = (t.difference(now)).abs();
          if (diff < bestDiff) {
            bestDiff = diff;
            bestIdx = i;
          }
        } catch (_) {}
      }
      _aqi = values[bestIdx].round();
    } catch (_) {
      // ignore
    }
  }

  // === Cache helpers ===
  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final map = <String, dynamic>{
        'ts': nowMs,
        'lat': _lat,
        'lon': _lon,
        'cityName': _cityName,
        'locationError': _locationError,
        'tempC': _tempC,
        'conditionText': _conditionText,
        'iconAsset': _iconAsset,
        'aqi': _aqi,
        'sunriseSecUtc': _sunriseSecUtc,
        'sunsetSecUtc': _sunsetSecUtc,
        'dayLengthMin': _dayLengthMin,
        'sunElapsedMin': _sunElapsedMin,
        'tzOffsetSec': _tzOffsetSec,
        'moonriseSecUtc': _moonriseSecUtc,
        'moonsetSecUtc': _moonsetSecUtc,
        'hourlyToday': _hourlyToday.map((e) => e.toJson()).toList(),
        'hourlyTomorrow': _hourlyTomorrow.map((e) => e.toJson()).toList(),
        'tabIndex': _tabIndex,
      };
      await prefs.setString(_cacheKey, jsonEncode(map));
      _cacheTsMs = nowMs;
    } catch (_) {}
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_cacheKey);
      if (str == null || str.isEmpty) return;
      final data = jsonDecode(str) as Map<String, dynamic>;
      final ts = (data['ts'] as num?)?.toInt();
      List<Hourly> toList(List? raw) => (raw ?? const [])
          .whereType<Map>()
          .map((m) => Hourly.fromJson(m.cast<String, dynamic>()))
          .toList();

      _cacheTsMs = ts;
      _lat = (data['lat'] as num?)?.toDouble();
      _lon = (data['lon'] as num?)?.toDouble();
      _cityName = data['cityName'] as String?;
      _locationError = data['locationError'] as String?;
      _tempC = (data['tempC'] as num?)?.toInt();
      _conditionText = data['conditionText'] as String?;
      _iconAsset = (data['iconAsset'] as String?) ?? _iconAsset;
      _aqi = (data['aqi'] as num?)?.toInt();
      _sunriseSecUtc = (data['sunriseSecUtc'] as num?)?.toInt();
      _sunsetSecUtc = (data['sunsetSecUtc'] as num?)?.toInt();
      _dayLengthMin = (data['dayLengthMin'] as num?)?.toInt();
      _sunElapsedMin = (data['sunElapsedMin'] as num?)?.toInt();
      _tzOffsetSec = (data['tzOffsetSec'] as num?)?.toInt();
      _moonriseSecUtc = (data['moonriseSecUtc'] as num?)?.toInt();
      _moonsetSecUtc = (data['moonsetSecUtc'] as num?)?.toInt();
      _hourlyToday = toList(data['hourlyToday'] as List?);
      _hourlyTomorrow = toList(data['hourlyTomorrow'] as List?);
      _tabIndex = (data['tabIndex'] as num?)?.toInt() ?? 0;
      _hourly = _tabIndex == 0 ? _hourlyToday : _hourlyTomorrow;
      notifyListeners();
    } catch (_) {}
  }

  String formatHm(int? utcSec) {
    if (utcSec == null) return '—';
    final dtUtc = DateTime.fromMillisecondsSinceEpoch(
      utcSec * 1000,
      isUtc: true,
    );
    final dtLocal = (_tzOffsetSec != null)
        ? dtUtc.add(Duration(seconds: _tzOffsetSec!))
        : dtUtc.toLocal();
    final hh = dtLocal.hour.toString().padLeft(2, '0');
    final mm = dtLocal.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String headerDateHu() {
    final nowUtc = DateTime.now().toUtc();
    final dt = (_tzOffsetSec != null)
        ? nowUtc.add(Duration(seconds: _tzOffsetSec!))
        : DateTime.now();
    const months = [
      'jan.',
      'febr.',
      'márc.',
      'ápr.',
      'máj.',
      'jún.',
      'júl.',
      'aug.',
      'szept.',
      'okt.',
      'nov.',
      'dec.',
    ];
    const weekdays = [
      'hétfő',
      'kedd',
      'szerda',
      'csütörtök',
      'péntek',
      'szombat',
      'vasárnap',
    ];
    final m = months[dt.month - 1];
    final d = dt.day;
    final wd = weekdays[dt.weekday - 1];
    return '$m $d, $wd';
  }

  int? _nullIfZero(num? v) {
    final i = v?.toInt();
    if (i == null || i <= 0) return null;
    return i;
  }
}
