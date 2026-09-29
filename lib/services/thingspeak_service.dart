import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/sensor_data.dart';

/// Result wrapper for ThingSpeak fetch operations.
enum DataSource { live, cached, none }

class FetchResult {
  final SensorData? latest;
  final List<SensorData> history;
  final DataSource source;
  final String? errorMessage;

  const FetchResult({
    this.latest,
    this.history = const [],
    required this.source,
    this.errorMessage,
  });

  bool get hasData   => latest != null;
  bool get hasError  => errorMessage != null;
  bool get isCached  => source == DataSource.cached;
  bool get isLive    => source == DataSource.live;
}

/// Service responsible for reading data from the ThingSpeak REST API.
///
/// SECURITY:
///   • Only READ requests are made — no writes to ThingSpeak.
///   • No ESP32 WRITE API key is used or stored here.
class ThingSpeakService {
  static const String _cacheKey = 'cached_latest_feed';

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Fetch the single latest sensor reading.
  /// Falls back to cached data if the network call fails.
  Future<FetchResult> fetchLatest() async {
    try {
      final response = await http
          .get(Uri.parse(AppConfig.latestFeedUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty || body == '{}') {
          return const FetchResult(
            source: DataSource.none,
            errorMessage: 'No sensor data available yet.',
          );
        }
        final json = jsonDecode(body) as Map<String, dynamic>;
        final data = SensorData.fromJson(json);
        await _cacheLatest(body); // persist for offline use
        return FetchResult(latest: data, source: DataSource.live);
      } else {
        return _tryCache('Server error ${response.statusCode}');
      }
    } catch (e) {
      return _tryCache('Unable to fetch live data.');
    }
  }

  /// Fetch the last [count] sensor readings for history / charts.
  Future<FetchResult> fetchHistory({int count = AppConfig.historyCount}) async {
    try {
      final url = AppConfig.recentFeedsUrl(count: count);
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final feeds = json['feeds'] as List<dynamic>? ?? [];
        final entries = feeds
            .whereType<Map<String, dynamic>>()
            .map(SensorData.fromJson)
            .toList();
        return FetchResult(
          latest: entries.isNotEmpty ? entries.last : null,
          history: entries,
          source: DataSource.live,
        );
      } else {
        return FetchResult(
          source: DataSource.none,
          errorMessage: 'Server error ${response.statusCode}',
        );
      }
    } catch (e) {
      return FetchResult(
        source: DataSource.none,
        errorMessage: 'Unable to fetch history.',
      );
    }
  }

  // ── Caching ─────────────────────────────────────────────────────────────────

  Future<void> _cacheLatest(String rawJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, rawJson);
    } catch (_) {}
  }

  Future<FetchResult> _tryCache(String errorMsg) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        final data = SensorData.fromJson(json);
        return FetchResult(
          latest: data,
          source: DataSource.cached,
          errorMessage: errorMsg,
        );
      }
    } catch (_) {}
    return FetchResult(source: DataSource.none, errorMessage: errorMsg);
  }
}

