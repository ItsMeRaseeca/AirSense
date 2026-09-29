import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/sensor_data.dart';
import '../services/location_service.dart';
import '../services/pdf_report_service.dart';
import '../services/thingspeak_service.dart';
import '../theme/app_theme.dart';
import '../widgets/air_quality_card.dart';
import '../widgets/chart_card.dart';
import '../widgets/connection_status.dart';
import '../widgets/gemini_explanation_sheet.dart';
import '../widgets/location_card.dart';
import '../widgets/sensor_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── Services ─────────────────────────────────────────────────────────────────
  final _tsService  = ThingSpeakService();
  final _locService = LocationService();

  // ── State ────────────────────────────────────────────────────────────────────
  SensorData?      _latest;
  List<SensorData> _history = [];
  FetchResult?     _fetchResult;
  LocationResult?  _location;

  bool _isLoading       = true;
  bool _locationLoading = false;
  String _errorMessage  = '';
  Timer? _refreshTimer;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchAll();
    _requestLocation();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────────

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: AppConfig.autoRefreshSeconds),
      (_) => _fetchLatestOnly(),
    );
  }

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading    = true;
      _errorMessage = '';
    });

    final result = await _tsService.fetchHistory(count: AppConfig.historyCount);
    if (!mounted) return;

    setState(() {
      _isLoading    = false;
      _fetchResult  = result;
      _history      = result.history;
      _latest       = result.latest;
      _errorMessage = result.errorMessage ?? '';
    });
  }

  Future<void> _fetchLatestOnly() async {
    final result = await _tsService.fetchLatest();
    if (!mounted) return;
    setState(() {
      _fetchResult = result;
      if (result.hasData) _latest = result.latest;
      if (result.errorMessage != null) _errorMessage = result.errorMessage!;
    });
  }

  Future<void> _requestLocation() async {
    setState(() => _locationLoading = true);
    final loc = await _locService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _location        = loc;
      _locationLoading = false;
    });
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  void _onGeneratePdfReport() {
    if (_latest == null && _history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sensor data available to generate report.'),
        ),
      );
      return;
    }
    PdfReportService.generateAndShareReport(
      latest: _latest,
      history: _history,
      location: _location,
    );
  }

  void _onExplainReadings() {
    if (_latest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waiting for sensor data to explain readings…'),
        ),
      );
      return;
    }
    GeminiExplanationSheet.show(
      context,
      latest: _latest!,
      history: _history,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  ConnectionStatus get _connectionStatus {
    if (_isLoading)                 return ConnectionStatus.loading;
    if (_fetchResult?.isCached ?? false) return ConnectionStatus.stale;
    if (_errorMessage.isNotEmpty && _latest == null) return ConnectionStatus.error;
    if (_latest == null)            return ConnectionStatus.error;

    final age = DateTime.now().difference(_latest!.timestamp).inSeconds;
    if (age <= AppConfig.staleThresholdSeconds) return ConnectionStatus.connected;
    return ConnectionStatus.stale;
  }

  String get _lastUpdatedLabel {
    if (_latest == null) return '—';
    final diff = DateTime.now().difference(_latest!.timestamp);
    if (diff.inSeconds < 60)  return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    return 'at ${DateFormat('h:mm a').format(_latest!.timestamp)}';
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.goldfinch,
        onRefresh: _fetchAll,
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
      expandedHeight: 0,
      flexibleSpace: const SizedBox.shrink(),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.bistro,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.air_rounded,
                color: AppColors.goldfinch, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AirSense',
                  style: AppTheme.sectionTitle.copyWith(fontSize: 18)),
              Text('Environmental monitoring',
                  style: AppTheme.caption.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.bistro, size: 20),
          tooltip: "Today's Report",
          onPressed: _onGeneratePdfReport,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.bistro),
          tooltip: 'Refresh',
          onPressed: _fetchAll,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection status badge
          Center(
            child: ConnectionStatusBadge(
              status: _connectionStatus,
              isCached: _fetchResult?.isCached ?? false,
            ),
          ),
          const SizedBox(height: 16),

          // Error banner (non-blocking)
          if (_errorMessage.isNotEmpty && _latest != null)
            _buildWarnBanner(),

          // Full error state
          if (_errorMessage.isNotEmpty && _latest == null && !_isLoading)
            _buildErrorState()
          else ...[
            // Hero Air Quality Card
            AirQualityCard(
              data: _latest,
              lastUpdatedLabel: _isLoading ? 'Loading…' : _lastUpdatedLabel,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 14),

            // Feature Action Buttons: Today's Report & Explain My Readings
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _onGeneratePdfReport,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text("Today's Report"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.bistro,
                      side: BorderSide(
                          color: AppColors.goldfinch.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: AppColors.cardWhite,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _onExplainReadings,
                    icon: const Icon(Icons.auto_awesome_rounded,
                        size: 16, color: AppColors.bistro),
                    label: const Text(
                      'Explain Readings',
                      style: TextStyle(
                          color: AppColors.bistro, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.butter,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Temperature + Humidity row
            Row(
              children: [
                Expanded(
                  child: SensorCard(
                    icon: Icons.thermostat_rounded,
                    label: 'Temperature',
                    value: _latest?.temperature?.toStringAsFixed(1) ?? '—',
                    unit: '°C',
                    accentColor: AppColors.goldfinch,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SensorCard(
                    icon: Icons.water_drop_rounded,
                    label: 'Humidity',
                    value: _latest?.humidity?.toStringAsFixed(1) ?? '—',
                    unit: '%',
                    accentColor: const Color(0xFF5BBFBA),
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // MQ135 card – full width for emphasis
            SensorCard(
              icon: Icons.sensors_rounded,
              label: 'MQ135 Raw',
              value: _latest?.mq135Raw?.toString() ?? '—',
              unit: 'RAW',
              accentColor: AppColors.bistro,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),

            // Mini trend chart (MQ135)
            if (_history.isNotEmpty) ...[
              _buildSectionLabel('Recent Trend'),
              const SizedBox(height: 10),
              ChartCard(
                title: 'MQ135',
                history: _history,
                color: AppColors.bistro,
                unit: 'raw',
                valueExtractor: (e) => (e.mq135Raw ?? 0).toDouble(),
              ),
              const SizedBox(height: 16),
            ],

            // Location
            _buildSectionLabel('Monitoring Location'),
            const SizedBox(height: 10),
            LocationCard(
              location: _location,
              isLoading: _locationLoading,
            ),
            const SizedBox(height: 16),

            // Last updated footer
            Center(
              child: Text(
                _isLoading
                    ? 'Fetching live data…'
                    : 'Updated $_lastUpdatedLabel',
                style: AppTheme.caption,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: AppTheme.sectionTitle);
  }

  Widget _buildWarnBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.butter.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldfinch.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.goldfinch),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage,
                style: AppTheme.caption
                    .copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.garnet.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded,
                color: AppColors.garnet, size: 34),
          ),
          const SizedBox(height: 20),
          Text('Unable to fetch live data',
              style: AppTheme.sectionTitle.copyWith(fontSize: 17)),
          const SizedBox(height: 8),
          Text(_errorMessage,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchAll,
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
}
