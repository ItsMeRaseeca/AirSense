/// SensorData model — represents one ThingSpeak feed entry.
///
/// Field mapping (as configured on the ThingSpeak channel):
///   field1 → temperature (°C)
///   field2 → humidity (%)
///   field3 → MQ135 raw ADC value
///   field4 → air-quality status (0 = NORMAL, 1 = POOR)
///
/// The ESP32 is the sole authority for the NORMAL/POOR classification.
/// Flutter reads Field 4 directly — it does NOT re-derive status from Field 3.
///
/// IMPORTANT: MQ135 raw values must NEVER be labelled as ppm or AQI.
class SensorData {
  final DateTime timestamp;
  final double? temperature; // °C, may be null if field missing
  final double? humidity;    // %, may be null if field missing
  final int? mq135Raw;       // raw ADC reading, may be null if field missing
  final bool? airPoor;       // true = POOR, false = NORMAL, null = unknown

  const SensorData({
    required this.timestamp,
    this.temperature,
    this.humidity,
    this.mq135Raw,
    this.airPoor,
  });

  // ── Derived helpers ─────────────────────────────────────────────────────────

  /// Human-readable status string sourced from Field 4.
  String get statusLabel {
    if (airPoor == null) return '—';
    return airPoor! ? 'POOR' : 'NORMAL';
  }

  bool get isNormal  => airPoor == false;
  bool get isPoor    => airPoor == true;
  bool get hasStatus => airPoor != null;

  // ── Parsing ─────────────────────────────────────────────────────────────────

  /// Parse from a ThingSpeak feed JSON object.
  /// Handles null, empty, and malformed field values gracefully.
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      timestamp : _parseTimestamp(json['created_at']),
      temperature: _parseDouble(json['field1']),
      humidity   : _parseDouble(json['field2']),
      mq135Raw   : _parseInt(json['field3']),
      airPoor    : _parseBoolField4(json['field4']),
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  static DateTime _parseTimestamp(dynamic raw) {
    if (raw == null) return DateTime.now();
    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static double? _parseDouble(dynamic raw) {
    if (raw == null || raw.toString().trim().isEmpty) return null;
    return double.tryParse(raw.toString().trim());
  }

  static int? _parseInt(dynamic raw) {
    if (raw == null || raw.toString().trim().isEmpty) return null;
    final d = double.tryParse(raw.toString().trim());
    return d?.round();
  }

  /// Field 4: "0" → NORMAL (false), "1" → POOR (true), anything else → null.
  static bool? _parseBoolField4(dynamic raw) {
    if (raw == null || raw.toString().trim().isEmpty) return null;
    final val = raw.toString().trim();
    if (val == '1') return true;
    if (val == '0') return false;
    return null;
  }

  @override
  String toString() =>
      'SensorData(ts=$timestamp, temp=$temperature, hum=$humidity, '
      'mq135=$mq135Raw, airPoor=$airPoor)';
}

