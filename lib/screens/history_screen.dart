import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/sensor_data.dart';
import '../services/thingspeak_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _tsService = ThingSpeakService();

  List<SensorData> _history = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading    = true;
      _errorMessage = '';
    });
    final result =
        await _tsService.fetchHistory(count: AppConfig.historyCount);
    if (!mounted) return;
    setState(() {
      _isLoading    = false;
      _history      = result.history;
      _errorMessage = result.errorMessage ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.goldfinch,
        onRefresh: _loadHistory,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: false,
      floating: true,
      backgroundColor: AppColors.background,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historical Data', style: AppTheme.sectionTitle.copyWith(fontSize: 20)),
          Text('Last ${AppConfig.historyCount} readings',
              style: AppTheme.caption.copyWith(fontSize: 10)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.bistro),
          tooltip: 'Refresh',
          onPressed: _loadHistory,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_errorMessage.isNotEmpty && _history.isEmpty) return _buildError();
    if (_history.isEmpty) return _buildEmpty();
    return _buildContent();
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Temperature chart
          _sectionLabel('Temperature'),
          const SizedBox(height: 10),
          ChartCard(
            title: 'Temperature',
            history: _history,
            color: AppColors.goldfinch,
            unit: '°C',
            valueExtractor: (e) => e.temperature ?? 0,
          ),
          const SizedBox(height: 16),

          // Humidity chart
          _sectionLabel('Humidity'),
          const SizedBox(height: 10),
          ChartCard(
            title: 'Humidity',
            history: _history,
            color: const Color(0xFF5BBFBA),
            unit: '%',
            valueExtractor: (e) => e.humidity ?? 0,
          ),
          const SizedBox(height: 16),

          // MQ135 chart
          _sectionLabel('MQ135 Raw'),
          const SizedBox(height: 10),
          ChartCard(
            title: 'MQ135',
            history: _history,
            color: AppColors.bistro,
            unit: 'raw',
            valueExtractor: (e) => (e.mq135Raw ?? 0).toDouble(),
          ),
          const SizedBox(height: 24),

          // Recent readings list
          _sectionLabel('Recent Readings'),
          const SizedBox(height: 10),
          _buildReadingsList(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) =>
      Text(text, style: AppTheme.sectionTitle);

  Widget _buildReadingsList() {
    final reversed = _history.reversed.toList();
    return Container(
      decoration: AppTheme.cardDecoration(),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: reversed.length,
        separatorBuilder: (context2, index2) => const Divider(
          color: AppColors.divider,
          height: 1,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (_, i) => _buildReadingTile(reversed[i], i),
      ),
    );
  }

  Widget _buildReadingTile(SensorData data, int index) {
    final isPoor = data.isPoor;
    final statusColor = isPoor ? AppColors.garnet : AppColors.goldfinch;
    final timeLabel = DateFormat('h:mm a').format(data.timestamp);
    final dateLabel = DateFormat('MMM d').format(data.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Time column
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeLabel,
                    style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 13)),
                Text(dateLabel, style: AppTheme.caption),
              ],
            ),
          ),

          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data.statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const Spacer(),

          // MQ135 value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.mq135Raw != null ? '${data.mq135Raw}' : '—',
                style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 15),
              ),
              Text('MQ135', style: AppTheme.caption),
            ],
          ),

          const SizedBox(width: 16),

          // Temperature
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.temperature != null
                    ? '${data.temperature!.toStringAsFixed(1)}°'
                    : '—',
                style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14),
              ),
              Text('Temp', style: AppTheme.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(
              color: AppColors.goldfinch,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 20),
            Text('Loading history…', style: AppTheme.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 48, color: AppColors.garnet),
          const SizedBox(height: 16),
          Text('Unable to load history',
              style: AppTheme.sectionTitle.copyWith(fontSize: 17)),
          const SizedBox(height: 8),
          Text(_errorMessage,
              style: AppTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bistro,
              foregroundColor: AppColors.butter,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Text(
          'No sensor data available yet.',
          style: AppTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

