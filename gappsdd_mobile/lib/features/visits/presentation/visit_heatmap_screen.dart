import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/client_visits_data.dart';

/// Radius (metres) used for both the circle markers and the density calculation.
const double _kRadius = 15.0;

class VisitHeatmapScreen extends ConsumerStatefulWidget {
  const VisitHeatmapScreen({super.key, required this.visitId});

  final String visitId;

  @override
  ConsumerState<VisitHeatmapScreen> createState() => _VisitHeatmapScreenState();
}

class _VisitHeatmapScreenState extends ConsumerState<VisitHeatmapScreen> {
  late Future<List<VisitLocationPoint>> _future;

  bool get _isCupertino => Theme.of(context).platform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _future = ref.read(visitsRepositoryProvider).loadVisitLocationPoints(widget.visitId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      _isCupertino ? CupertinoIcons.back : Icons.arrow_back_rounded,
                    ),
                    color: AppColors.primary,
                  ),
                  Text(
                    'Mapa de Actividad',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<VisitLocationPoint>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final points = snapshot.data ?? [];

                  if (points.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_outlined, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'No hay datos de ubicación para esta visita',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final circles = _buildCircles(points);
                  final latLngs = points.map((p) => LatLng(p.lat, p.lng)).toList();
                  final initialCamera = _fitCamera(latLngs);

                  return ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                        child: FlutterMap(
                          options: MapOptions(initialCameraFit: initialCamera),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.gapp.gappsdd',
                            ),
                            CircleLayer(circles: circles),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds [CircleMarker]s with density-based color (yellow → red).
  List<CircleMarker> _buildCircles(List<VisitLocationPoint> points) {
    // Compute neighbourhood density for each point.
    final counts = List<int>.filled(points.length, 0);
    for (var i = 0; i < points.length; i++) {
      for (var j = 0; j < points.length; j++) {
        if (i != j && _distanceMeters(points[i], points[j]) <= _kRadius) {
          counts[i]++;
        }
      }
    }

    final maxCount = counts.reduce(math.max);

    return List.generate(points.length, (i) {
      final t = maxCount > 0 ? counts[i] / maxCount : 0.0;
      return CircleMarker(
        point: LatLng(points[i].lat, points[i].lng),
        radius: _kRadius,
        useRadiusInMeter: true,
        color: _colorForDensity(t),
      );
    });
  }

  /// Maps density [t] ∈ [0, 1] to a color: yellow (sparse) → red (dense).
  Color _colorForDensity(double t) {
    final hue = 60.0 * (1.0 - t); // 60° = yellow, 0° = red
    final alpha = 0.30 + 0.45 * t;
    return HSVColor.fromAHSV(alpha, hue, 1.0, 1.0).toColor();
  }

  /// Returns a [CameraFit] that shows all [latLngs] with padding.
  CameraFit _fitCamera(List<LatLng> latLngs) {
    return CameraFit.coordinates(
      coordinates: latLngs,
      padding: const EdgeInsets.all(60),
      // Clamp zoom so a single point doesn't zoom in to street level.
      maxZoom: 19,
    );
  }

  /// Haversine distance in metres between two location points.
  double _distanceMeters(VisitLocationPoint a, VisitLocationPoint b) {
    const r = 6371000.0; // Earth radius in metres
    final lat1 = a.lat * math.pi / 180;
    final lat2 = b.lat * math.pi / 180;
    final dLat = (b.lat - a.lat) * math.pi / 180;
    final dLng = (b.lng - a.lng) * math.pi / 180;
    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * r * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }
}
