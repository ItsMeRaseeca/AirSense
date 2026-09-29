import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: false,
      floating: true,
      backgroundColor: AppColors.background,
      title: Text('About', style: AppTheme.sectionTitle.copyWith(fontSize: 20)),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero branding card
          _buildHeroCard(),
          const SizedBox(height: 20),

          // Hardware section
          _buildInfoCard(
            title: 'Hardware',
            items: [
              _InfoItem(
                icon: Icons.memory_rounded,
                label: 'Microcontroller',
                value: 'ESP32',
              ),
              _InfoItem(
                icon: Icons.sensors_rounded,
                label: 'Gas Sensor',
                value: 'MQ135',
              ),
              _InfoItem(
                icon: Icons.thermostat_rounded,
                label: 'Climate Sensor',
                value: 'DHT22',
              ),
              _InfoItem(
                icon: Icons.display_settings_rounded,
                label: 'Display',
                value: '16×2 I2C LCD',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Cloud section
          _buildInfoCard(
            title: 'Cloud',
            items: [
              _InfoItem(
                icon: Icons.cloud_rounded,
                label: 'Platform',
                value: 'ThingSpeak',
              ),
              _InfoItem(
                icon: Icons.tag_rounded,
                label: 'Channel ID',
                value: AppConfig.channelId,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mobile section
          _buildInfoCard(
            title: 'Mobile App',
            items: [
              _InfoItem(
                icon: Icons.phone_android_rounded,
                label: 'Framework',
                value: 'Flutter',
              ),
              _InfoItem(
                icon: Icons.info_rounded,
                label: 'Version',
                value: AppConfig.appVersion,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Data integrity note
          _buildNoteCard(),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.heroCardDecoration(poor: false),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.goldfinch.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.goldfinch.withValues(alpha: 0.4), width: 1.5),
            ),
            child: const Icon(Icons.air_rounded,
                color: AppColors.goldfinch, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            AppConfig.appName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppConfig.appSubtitle,
            style: AppTheme.heroLabel.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text(
            'IoT-Based Air Quality Monitoring System',
            style: AppTheme.heroLabel.copyWith(letterSpacing: 0, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<_InfoItem> items,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Text(
              title.toUpperCase(),
              style: AppTheme.cardLabel,
            ),
          ),
          const Divider(color: AppColors.divider, height: 1, indent: 20),
          ...items.map((item) => _buildInfoTile(item)),
        ],
      ),
    );
  }

  Widget _buildInfoTile(_InfoItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.goldfinch.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(item.icon, color: AppColors.goldfinch, size: 18),
          ),
          const SizedBox(width: 14),
          Text(item.label, style: AppTheme.bodyMedium),
          const Spacer(),
          Text(
            item.value,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.butter.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldfinch.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: AppColors.goldfinch, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Air quality data is provided by the ESP32 via ThingSpeak. '
              'The NORMAL / POOR status is determined by the ESP32 firmware — '
              'this app displays it as-is.',
              style: AppTheme.bodyMedium.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({required this.icon, required this.label, required this.value});
}

