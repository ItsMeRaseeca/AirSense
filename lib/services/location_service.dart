import 'package:geolocator/geolocator.dart';

/// Result of a location query.
class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? locality;   // city / town
  final String? adminArea;  // state / province
  final String? errorMessage;

  const LocationResult({
    this.latitude,
    this.longitude,
    this.locality,
    this.adminArea,
    this.errorMessage,
  });

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasPlace    => locality != null || adminArea != null;

  String get placeName {
    if (locality != null && adminArea != null) return '$locality, $adminArea';
    return locality ?? adminArea ?? '';
  }
}

/// Service responsible for obtaining the device's current GPS location.
///
/// Used as a proxy for "monitoring location" because the ESP32 hardware
/// has no GPS module.  The phone and sensor are co-located during demos.
///
/// Location is OPTIONAL — the app continues working if permission is denied.
class LocationService {
  /// Returns the current device location, or a [LocationResult] with an
  /// error message if permission is denied / services are off.
  Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Location services enabled?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          errorMessage: 'Location services are disabled on this device.',
        );
      }

      // 2. Permission check / request.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationResult(
          errorMessage: 'Location permission not granted.',
        );
      }

      // 3. Get the actual position.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return LocationResult(
        latitude : position.latitude,
        longitude: position.longitude,
        // City / state resolved via reverse-geocode in the widget layer
        // to keep this service dependency-light.
      );
    } catch (e) {
      return LocationResult(
        errorMessage: 'Could not determine location.',
      );
    }
  }

  /// Check current permission status without requesting it.
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}

