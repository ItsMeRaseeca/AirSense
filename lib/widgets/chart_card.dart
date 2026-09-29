import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_data.dart';
import '../theme/app_theme.dart';

/// A premium line-chart card for historical sensor data.
///
/// [title]      – section label shown above the chart
/// [dataPoints] – list of (timestamp, value) pairs extracted from SensorData
/// [color]      – accent color for the chart line and gradient fill
/// [unit]       – unit label shown on the Y axis tooltip
class ChartCard extends StatelessWidget {
  final String title;
  final List<SensorData> history;
  final Color color;
  final String unit;
  final double Function(SensorData) valueExtractor;

  const ChartCard({
    super.key,
    required this.title,
    required this.history,
    required this.color,
    required this.unit,
    required this.valueExtractor,
  });

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.sectionTitle.copyWith(fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            '${history.length} readings',
            style: AppTheme.caption,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'No chart data',
                      style: AppTheme.caption,
                    ),
                  )
                : LineChart(_buildChart(spots)),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    final valid = history
        .where((e) {
          try {
            final v = valueExtractor(e);
            return v.isFinite;
          } catch (_) {
            return false;
          }
        })
        .toList();

    if (valid.isEmpty) return [];

    return List.generate(valid.length, (i) {
      final v = valueExtractor(valid[i]);
      return FlSpot(i.toDouble(), v);
    });
  }

  LineChartData _buildChart(List<FlSpot> spots) {
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs();
    final pad   = range < 1 ? 2.0 : range * 0.2;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (range < 1 ? 1.0 : range / 4).clamp(0.5, 500.0).toDouble(),
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColors.divider,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: (value, _) => Text(
              value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1),
              style: AppTheme.caption.copyWith(fontSize: 10),
            ),
            interval: (range < 1 ? 1.0 : range / 4).clamp(0.5, 500.0).toDouble(),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: (spots.length / 4).clamp(1, 999).roundToDouble(),
            getTitlesWidget: (value, _) {
              final idx = value.toInt();
              if (idx < 0 || idx >= history.length) {
                return const SizedBox.shrink();
              }
              final ts = history[idx].timestamp;
              return Text(
                DateFormat('HH:mm').format(ts),
                style: AppTheme.caption.copyWith(fontSize: 9),
              );
            },
          ),
        ),
        rightTitles : const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles   : const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minY: minY - pad,
      maxY: maxY + pad,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: color,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.18),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.bistro.withValues(alpha: 0.9),
          tooltipRoundedRadius: 8,
          getTooltipItems: (spots) => spots
              .map(
                (s) => LineTooltipItem(
                  '${s.y.toStringAsFixed(s.y.truncateToDouble() == s.y ? 0 : 1)} $unit',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

