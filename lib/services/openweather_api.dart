import 'dart:convert';
import 'package:http/http.dart' as http;

/// Lightweight client for OpenWeatherMap REST APIs.
///
/// Provide an API key explicitly or use the fromEnvironment() factory and pass
/// --dart-define=OWM_API_KEY=your_key when running the app.
class OpenWeatherApi {
  OpenWeatherApi({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  factory OpenWeatherApi.fromEnvironment({http.Client? client}) {
    const key = String.fromEnvironment('OWM_API_KEY');
    if (key.isEmpty) {
      throw StateError(
        'OWM_API_KEY is not set. Pass --dart-define=OWM_API_KEY=YOUR_KEY or use --dart-define-from-file=weather.env',
      );
    }
    return OpenWeatherApi(apiKey: key, client: client);
  }

  final String apiKey;
  final http.Client _client;
  static const _host = 'api.openweathermap.org';

  /// Get current weather by city name
  Future<Map<String, dynamic>> currentByCity(
    String city, {
    String units = 'metric',
    String lang = 'en',
  }) {
    return _get('/data/2.5/weather', {'q': city, 'units': units, 'lang': lang});
  }

  /// Get current weather by geographic coordinates
  Future<Map<String, dynamic>> currentByCoords(
    double lat,
    double lon, {
    String units = 'metric',
    String lang = 'en',
  }) {
    return _get('/data/2.5/weather', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'units': units,
      'lang': lang,
    });
  }

  /// 5 day / 3 hour forecast by city name
  Future<Map<String, dynamic>> forecastByCity(
    String city, {
    String units = 'metric',
    String lang = 'en',
  }) {
    return _get('/data/2.5/forecast', {
      'q': city,
      'units': units,
      'lang': lang,
    });
  }

  /// 5 day / 3 hour forecast by coordinates
  Future<Map<String, dynamic>> forecastByCoords(
    double lat,
    double lon, {
    String units = 'metric',
    String lang = 'en',
  }) {
    return _get('/data/2.5/forecast', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'units': units,
      'lang': lang,
    });
  }

  /// One Call 3.0 (current + hourly + daily)
  Future<Map<String, dynamic>> oneCall(
    double lat,
    double lon, {
    String units = 'metric',
    String lang = 'en',
    List<String> exclude = const ['minutely', 'alerts'],
  }) {
    return _get('/data/3.0/onecall', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'units': units,
      'lang': lang,
      if (exclude.isNotEmpty) 'exclude': exclude.join(','),
    });
  }

  /// Air Pollution API: current air quality by coordinates
  Future<Map<String, dynamic>> airQuality(double lat, double lon) {
    return _get('/data/2.5/air_pollution', {
      'lat': lat.toString(),
      'lon': lon.toString(),
    });
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final uri = Uri.https(_host, path, {...query, 'appid': apiKey});

    final res = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = json.decode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('Unexpected response format');
    }

    throw OpenWeatherApiException(
      _extractErrorMessage(res.body) ?? 'Request failed',
      res.statusCode,
    );
  }

  String? _extractErrorMessage(String body) {
    try {
      final data = json.decode(body);
      if (data is Map<String, dynamic>) {
        return data['message']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void close() => _client.close();
}

class OpenWeatherApiException implements Exception {
  OpenWeatherApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;
  @override
  String toString() => 'OpenWeatherApiException($statusCode): $message';
}
