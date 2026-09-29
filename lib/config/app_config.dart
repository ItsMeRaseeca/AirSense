/// AirSense App Configuration
/// ─────────────────────────────────────────────────────────────────────────────
/// All ThingSpeak connection parameters and Gemini API settings are defined here.
///
/// SECURITY RULES:
///   • Only a READ API key may be used here — never the ESP32 WRITE key.
///   • If the ThingSpeak channel is set to PUBLIC, leave [readApiKey] empty ('').
///   • Do NOT commit private API keys to public source repositories.
/// ─────────────────────────────────────────────────────────────────────────────
class AppConfig {
  AppConfig._(); // prevent instantiation

  // ── ThingSpeak Configuration ──────────────────────────────────────────────

  /// Public ThingSpeak channel ID.
  static const String channelId = '3513305';

  /// READ API key. Leave empty ('') if the channel is public.
  /// ⚠️ NEVER put the ESP32 WRITE API key here.
  static const String readApiKey = String.fromEnvironment(
    'THINGSPEAK_READ_API_KEY',
    defaultValue: '',
  );

  // ── Gemini AI Configuration ────────────────────────────────────────────────

  /// Gemini API key for "Explain My Readings".
  /// Configurable via --dart-define=GEMINI_API_KEY=your_key or local setup.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // ── ThingSpeak Endpoints ────────────────────────────────────────────────────

  static String get baseUrl =>
      'https://api.thingspeak.com/channels/$channelId';

  /// Latest single feed entry.
  static String get latestFeedUrl {
    final key = readApiKey.isNotEmpty ? '?api_key=$readApiKey' : '';
    return '$baseUrl/feeds/last.json$key';
  }

  /// Recent [count] feed entries.
  static String recentFeedsUrl({int count = 30}) {
    final sep = readApiKey.isNotEmpty ? '&' : '?';
    final key = readApiKey.isNotEmpty ? '?api_key=$readApiKey' : '';
    return '$baseUrl/feeds.json$key${sep}results=$count';
  }

  // ── Refresh / Staleness ─────────────────────────────────────────────────────

  /// How often the app auto-refreshes (seconds).
  static const int autoRefreshSeconds = 20;

  /// A ThingSpeak reading older than this is considered "stale".
  static const int staleThresholdSeconds = 90;

  // ── History ─────────────────────────────────────────────────────────────────

  /// Number of historic entries fetched for charts.
  static const int historyCount = 30;

  // ── App Info ────────────────────────────────────────────────────────────────
  static const String appName = 'AirSense';
  static const String appSubtitle = 'Smart Air Quality Monitoring';
  static const String appVersion = '1.0.0';
}
