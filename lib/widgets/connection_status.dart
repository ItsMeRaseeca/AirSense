import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animated pulsing status dot shown on the Air Quality hero card.
/// Renders a small circle that smoothly pulses between two scales.
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({super.key, required this.color, this.size = 10});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.75, end: 1.25).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.55),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Connection / data freshness badge shown below the app bar.
enum ConnectionStatus { connected, stale, error, loading }

class ConnectionStatusBadge extends StatelessWidget {
  final ConnectionStatus status;
  final bool isCached;

  const ConnectionStatusBadge({
    super.key,
    required this.status,
    this.isCached = false,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _resolve() {
    if (isCached) return ('Cached · Offline', AppColors.dotStale);
    switch (status) {
      case ConnectionStatus.connected:
        return ('Live Data', AppColors.dotConnected);
      case ConnectionStatus.stale:
        return ('Data Stale', AppColors.dotStale);
      case ConnectionStatus.error:
        return ('No Connection', AppColors.dotError);
      case ConnectionStatus.loading:
        return ('Connecting…', AppColors.textMuted);
    }
  }
}

