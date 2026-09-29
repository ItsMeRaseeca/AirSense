import 'package:flutter/material.dart';

import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import 'connection_status.dart';

/// The hero card at the top of the dashboard.
///
/// Redesigned to feature:
///   • Light, warm off-white surface (#FFFDF8 / #FAF7F2) for BOTH states
///   • Clear status colors (Goldfinch #E6A341 for NORMAL, Indian Red #B14A36 for POOR)
///   • Accurate technical subtitles: "Within configured threshold" vs "Reading is above the configured threshold"
///   • Subtle, Apple-inspired environmental nature/warning animation
///   • MQ135 raw reading (never labelled as ppm or AQI)
class AirQualityCard extends StatelessWidget {
  final SensorData? data;
  final String lastUpdatedLabel;
  final bool isLoading;

  const AirQualityCard({
    super.key,
    required this.data,
    required this.lastUpdatedLabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPoor = data?.isPoor ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      decoration: AppTheme.heroCardDecoration(poor: isPoor),
      padding: const EdgeInsets.all(24),
      child: isLoading ? _buildSkeleton() : _buildContent(isPoor),
    );
  }

  Widget _buildContent(bool isPoor) {
    final dotColor = isPoor ? AppColors.indianRed : AppColors.goldfinch;
    final statusColor = isPoor ? AppColors.indianRed : AppColors.goldfinch;
    final statusText = data?.statusLabel ?? '—';
    final subtitleText = isPoor
        ? 'Reading is above the configured threshold'
        : 'Within configured threshold';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: label + pulsing dot
        Row(
          children: [
            Text(
              'AIR QUALITY',
              style: AppTheme.cardLabel.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            PulsingDot(color: dotColor, size: 10),
          ],
        ),
        const SizedBox(height: 16),

        // Status text + Subtitle + Nature/Warning animation icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                    child: Text(statusText),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: AppTheme.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                    child: Text(subtitleText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            NatureStatusAnimation(isPoor: isPoor),
          ],
        ),
        const SizedBox(height: 20),

        // Divider
        Container(
          height: 1,
          color: AppColors.divider,
        ),
        const SizedBox(height: 18),

        // MQ135 row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MQ135',
                  style: AppTheme.cardLabel.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data?.mq135Raw != null ? '${data!.mq135Raw}' : '—',
                  style: AppTheme.cardValue.copyWith(
                    fontSize: 40,
                    color: AppColors.bistro,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'RAW',
                style: AppTheme.cardLabel.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Last updated
        Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 13,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              lastUpdatedLabel,
              style: AppTheme.caption.copyWith(fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _shimmer(width: 100, height: 12),
            const Spacer(),
            _shimmer(width: 10, height: 10, circular: true),
          ],
        ),
        const SizedBox(height: 20),
        _shimmer(width: 160, height: 42),
        const SizedBox(height: 20),
        Container(height: 1, color: AppColors.divider),
        const SizedBox(height: 18),
        _shimmer(width: 100, height: 48),
        const SizedBox(height: 18),
        _shimmer(width: 140, height: 12),
      ],
    );
  }

  Widget _shimmer({
    required double width,
    required double height,
    bool circular = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bistro.withValues(alpha: 0.08),
        borderRadius:
            circular ? BorderRadius.circular(99) : BorderRadius.circular(6),
      ),
    );
  }
}

/// Subtle, Apple-inspired animated environmental nature / warning icon widget.
class NatureStatusAnimation extends StatefulWidget {
  final bool isPoor;

  const NatureStatusAnimation({super.key, required this.isPoor});

  @override
  State<NatureStatusAnimation> createState() => _NatureStatusAnimationState();
}

class _NatureStatusAnimationState extends State<NatureStatusAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.12, end: 0.28).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isPoor ? AppColors.indianRed : AppColors.goldfinch;
    final bgColor = widget.isPoor ? const Color(0xFFFDF0EE) : const Color(0xFFFEF3DD);
    final iconData = widget.isPoor
        ? Icons.cloud_queue_rounded
        : Icons.wb_sunny_rounded;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: AnimatedBuilder(
        key: ValueKey<bool>(widget.isPoor),
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: Border.all(
                  color: color.withValues(alpha: _opacityAnimation.value + 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: _opacityAnimation.value),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  iconData,
                  color: color,
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
