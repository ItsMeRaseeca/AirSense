import 'package:flutter/material.dart';

import '../models/sensor_data.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

class GeminiExplanationSheet extends StatefulWidget {
  final SensorData latest;
  final List<SensorData> history;

  const GeminiExplanationSheet({
    super.key,
    required this.latest,
    required this.history,
  });

  static void show(
    BuildContext context, {
    required SensorData latest,
    required List<SensorData> history,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GeminiExplanationSheet(
        latest: latest,
        history: history,
      ),
    );
  }

  @override
  State<GeminiExplanationSheet> createState() => _GeminiExplanationSheetState();
}

class _GeminiExplanationSheetState extends State<GeminiExplanationSheet> {
  bool _isLoading = true;
  String? _explanationText;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchExplanation();
  }

  Future<void> _fetchExplanation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _explanationText = null;
    });

    final result = await GeminiService.explainReadings(
      latest: widget.latest,
      history: widget.history,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _explanationText = result.text;
      } else {
        _errorMessage = result.errorMessage ?? 'Failed to load AI explanation.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPoor = widget.latest.isPoor;
    final statusColor = isPoor ? AppColors.indianRed : AppColors.goldfinch;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldfinch.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.goldfinch,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Understanding your readings',
                      style: AppTheme.sectionTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI explanation powered by Gemini',
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.bistro),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Metrics Grid Summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                _metricTile(
                  label: 'Temperature',
                  value: widget.latest.temperature != null
                      ? '${widget.latest.temperature!.toStringAsFixed(1)}°C'
                      : '—',
                  icon: Icons.thermostat_rounded,
                  color: AppColors.goldfinch,
                ),
                _dividerVertical(),
                _metricTile(
                  label: 'Humidity',
                  value: widget.latest.humidity != null
                      ? '${widget.latest.humidity!.toStringAsFixed(1)}%'
                      : '—',
                  icon: Icons.water_drop_rounded,
                  color: const Color(0xFF5BBFBA),
                ),
                _dividerVertical(),
                _metricTile(
                  label: 'MQ135',
                  value: widget.latest.mq135Raw != null
                      ? '${widget.latest.mq135Raw} raw'
                      : '—',
                  icon: Icons.sensors_rounded,
                  color: AppColors.bistro,
                ),
                _dividerVertical(),
                _metricTile(
                  label: 'Status',
                  value: widget.latest.statusLabel,
                  icon: isPoor ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                  color: statusColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content Area (Expanded to fill available height & fully scrollable)
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildExplanationContent(),
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.caption.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.sectionTitle.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _dividerVertical() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.divider,
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              color: AppColors.goldfinch,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing sensor readings with Gemini…',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.bistro,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Synthesizing environmental context',
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.butter.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldfinch.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.goldfinch, size: 32),
          const SizedBox(height: 12),
          Text(
            'Unable to generate AI explanation',
            style: AppTheme.sectionTitle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage!,
            style: AppTheme.caption.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchExplanation,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bistro,
              foregroundColor: AppColors.butter,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded,
                  color: AppColors.goldfinch, size: 18),
              const SizedBox(width: 6),
              Text(
                'Gemini Analysis',
                style: AppTheme.sectionTitle.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _explanationText!,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
