import 'dart:async';

import 'package:geolocator/geolocator.dart';

typedef OnLocationPoint = void Function(double lat, double lng, double? accuracy);

/// Periodically reads GPS position while an active visit is in progress.
///
/// Uses "When In Use" location permission only — no background modes needed.
/// Readings are taken every [intervalSeconds] (default 30 s). The first
/// reading is taken immediately when [start] is called.
class LocationTracker {
  LocationTracker({
    required this.onPoint,
    this.intervalSeconds = 30,
  });

  final OnLocationPoint onPoint;
  final int intervalSeconds;

  Timer? _timer;
  bool _running = false;

  bool get isRunning => _running;

  /// Requests permission if needed and starts periodic polling.
  /// Returns true if tracking started, false if permission was denied.
  Future<bool> start() async {
    if (_running) return true;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    _running = true;
    await _record(); // immediate first reading
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) => _record());
    return true;
  }

  /// Stops periodic polling. Safe to call multiple times.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  Future<void> _record() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      onPoint(pos.latitude, pos.longitude, pos.accuracy);
    } catch (_) {
      // Silently skip — bad GPS fix, timeout, or service unavailable.
    }
  }
}
