import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// Location card showing:
///   • Monitoring location coordinates
///   • Optional small map (flutter_map, no API key required)
///
/// The location comes from the PHONE's GPS — there is no GPS on the ESP32.
/// Labelled clearly as "Monitoring Location", never "ESP32 GPS Location".
class LocationCard extends StatefulWidget {
  final LocationResult? location;
  final bool isLoading;

  const LocationCard({super.key, this.location, this.isLoading = false});

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: widget.isLoading
          ? _buildSkeleton()
          : widget.location == null
              ? _buildRequestPrompt()
              : widget.location!.hasLocation
                  ? _buildLocationContent()
                  : _buildUnavailable(),
    );
  }

  // ── Unavailable state ────────────────────────────────────────────────────────
  Widget _buildUnavailable() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.textMuted.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.location_off_rounded,
              color: AppColors.textMuted, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MONITORING LOCATION', style: AppTheme.cardLabel),
              const SizedBox(height: 4),
              Text(
                widget.location?.errorMessage ?? 'Location unavailable',
                style: AppTheme.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Request prompt ───────────────────────────────────────────────────────────
  Widget _buildRequestPrompt() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.goldfinch.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.location_on_rounded,
              color: AppColors.goldfinch, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Tap to show monitoring location',
            style: AppTheme.caption,
          ),
        ),
      ],
    );
  }

  // ── Location content ─────────────────────────────────────────────────────────
  Widget _buildLocationContent() {
    final loc = widget.location!;
    final lat  = loc.latitude!;
    final lng  = loc.longitude!;
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.goldfinch.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: AppColors.goldfinch, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MONITORING LOCATION', style: AppTheme.cardLabel),
                  if (loc.hasPlace)
                    Text(loc.placeName,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        )),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Coordinates
        Row(
          children: [
            _coordChip(
                '${lat.abs().toStringAsFixed(4)}° $latDir', Icons.north_rounded),
            const SizedBox(width: 10),
            _coordChip(
                '${lng.abs().toStringAsFixed(4)}° $lngDir', Icons.east_rounded),
          ],
        ),
        const SizedBox(height: 14),

        // Toggle map button
        GestureDetector(
          onTap: () => setState(() => _showMap = !_showMap),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _showMap ? 'Hide map' : 'View map',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.goldfinch,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _showMap
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.goldfinch,
                size: 18,
              ),
            ],
          ),
        ),

        // Mini map
        if (_showMap) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 14,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.airsense.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.bistro,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.goldfinch, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.bistro.withValues(alpha: 0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.sensors,
                              color: AppColors.goldfinch, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _coordChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(text,
              style: AppTheme.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.textMuted.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 130,
                height: 12,
                decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 6),
            Container(
                width: 90,
                height: 12,
                decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6))),
          ],
        ),
      ],
    );
  }
}

