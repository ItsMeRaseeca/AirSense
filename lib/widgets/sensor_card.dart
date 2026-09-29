import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A compact sensor metric card.
///
/// Shows an icon, a category label, a large numeric value, and a unit label.
/// Used for Temperature, Humidity, and MQ135 readings.
class SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color? accentColor;
  final bool isLoading;

  const SensorCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.accentColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.goldfinch;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: isLoading ? _buildSkeleton() : _buildContent(accent),
    );
  }

  Widget _buildContent(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(height: 14),

        // Label
        Text(
          label.toUpperCase(),
          style: AppTheme.cardLabel,
        ),
        const SizedBox(height: 4),

        // Value + unit
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                value,
                style: AppTheme.cardValue,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(unit, style: AppTheme.cardUnit),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _skimmer(38, 38, circular: false),
        const SizedBox(height: 14),
        _skimmer(60, 12),
        const SizedBox(height: 4),
        _skimmer(80, 36),
      ],
    );
  }

  Widget _skimmer(double w, double h, {bool circular = false}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.18),
        borderRadius: circular
            ? BorderRadius.circular(99)
            : BorderRadius.circular(8),
      ),
    );
  }
}

