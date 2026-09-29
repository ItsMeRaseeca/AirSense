import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/sensor_data.dart';
import '../services/location_service.dart';

/// PDF Report Generator for AirSense
class PdfReportService {
  // AirSense Color Palette in PDF format
  static final pdfBistro    = PdfColor.fromHex('#210100');
  static final pdfGoldfinch = PdfColor.fromHex('#E6A341');
  static final pdfButter    = PdfColor.fromHex('#FECE79');
  static final pdfIndianRed = PdfColor.fromHex('#B14A36');
  static final pdfGarnet    = PdfColor.fromHex('#8C0902');
  static final pdfBg        = PdfColor.fromHex('#FAF7F2');
  static final pdfWhite     = PdfColor.fromHex('#FFFFFF');
  static final pdfTextMuted = PdfColor.fromHex('#7A5C54');

  /// Generate and present PDF report for saving / sharing
  static Future<void> generateAndShareReport({
    required SensorData? latest,
    required List<SensorData> history,
    LocationResult? location,
  }) async {
    final pdfBytes = await buildPdf(
      latest: latest,
      history: history,
      location: location,
    );

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'AirSense_Daily_Report_$dateStr.pdf',
    );
  }

  /// Build the PDF byte array
  static Future<Uint8List> buildPdf({
    required SensorData? latest,
    required List<SensorData> history,
    LocationResult? location,
  }) async {
    final pdf = pw.Document();

    // Filter today's readings if available, otherwise use all available history entries
    final now = DateTime.now();
    final todayReadings = history.where((data) {
      return data.timestamp.year == now.year &&
          data.timestamp.month == now.month &&
          data.timestamp.day == now.day;
    }).toList();

    // If todayReadings is empty, fallback to available history
    final dataList = todayReadings.isNotEmpty ? todayReadings : history;
    final isPartial = todayReadings.isEmpty && history.isNotEmpty;

    // Metrics calculation
    final totalCount = dataList.length;

    // Temps
    final temps = dataList.map((e) => e.temperature).whereType<double>().toList();
    final latestTemp = latest?.temperature;
    final avgTemp = temps.isNotEmpty ? temps.reduce((a, b) => a + b) / temps.length : null;
    final minTemp = temps.isNotEmpty ? temps.reduce((a, b) => a < b ? a : b) : null;
    final maxTemp = temps.isNotEmpty ? temps.reduce((a, b) => a > b ? a : b) : null;

    // Humidity
    final hums = dataList.map((e) => e.humidity).whereType<double>().toList();
    final latestHum = latest?.humidity;
    final avgHum = hums.isNotEmpty ? hums.reduce((a, b) => a + b) / hums.length : null;
    final minHum = hums.isNotEmpty ? hums.reduce((a, b) => a < b ? a : b) : null;
    final maxHum = hums.isNotEmpty ? hums.reduce((a, b) => a > b ? a : b) : null;

    // MQ135
    final mqs = dataList.map((e) => e.mq135Raw).whereType<int>().toList();
    final latestMq = latest?.mq135Raw;
    final avgMq = mqs.isNotEmpty ? (mqs.reduce((a, b) => a + b) / mqs.length).round() : null;
    final minMq = mqs.isNotEmpty ? mqs.reduce((a, b) => a < b ? a : b) : null;
    final maxMq = mqs.isNotEmpty ? mqs.reduce((a, b) => a > b ? a : b) : null;

    // Statuses
    final normalCount = dataList.where((e) => e.isNormal).length;
    final poorCount = dataList.where((e) => e.isPoor).length;
    final normalPct = totalCount > 0 ? (normalCount / totalCount * 100).toStringAsFixed(1) : '0';
    final poorPct = totalCount > 0 ? (poorCount / totalCount * 100).toStringAsFixed(1) : '0';

    final latestStatusStr = latest?.statusLabel ?? 'N/A';
    final isLatestPoor = latest?.isPoor ?? false;

    final locationStr = location != null && location.placeName.isNotEmpty
        ? location.placeName
        : 'Local Sensor Station';

    final fontBold = await PdfGoogleFonts.interBold();
    final fontRegular = await PdfGoogleFonts.interRegular();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── 1. HEADER BRANDING ─────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: pdfBistro,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AirSense',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 24,
                            color: pdfGoldfinch,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'DAILY ENVIRONMENTAL AIR QUALITY REPORT',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 10,
                            color: pdfButter,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          DateFormat('EEEE, MMM d, yyyy').format(now),
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 11,
                            color: pdfWhite,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          locationStr,
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 9,
                            color: pdfButter,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ── 2. EXECUTIVE SUMMARY BOX ───────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: pdfBg,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: pdfGoldfinch, width: 0.8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Latest Air Quality Status: $latestStatusStr',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 13,
                            color: isLatestPoor ? pdfGarnet : pdfBistro,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          isPartial
                              ? 'Note: Report based on available recent readings ($totalCount total).'
                              : 'Total readings recorded today: $totalCount',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 9,
                            color: pdfTextMuted,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: isLatestPoor ? pdfGarnet : pdfGoldfinch,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        latestStatusStr,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 11,
                          color: pdfWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ── 3. SENSOR METRICS SUMMARY TABLE ────────────────────────────
              pw.Text(
                'Sensor Readings Summary',
                style: pw.TextStyle(font: fontBold, fontSize: 13, color: pdfBistro),
              ),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E8E0D5'), width: 0.5),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: pdfBistro),
                    children: [
                      _tableCell('Parameter', font: fontBold, color: pdfWhite),
                      _tableCell('Latest', font: fontBold, color: pdfWhite),
                      _tableCell('Average', font: fontBold, color: pdfWhite),
                      _tableCell('Minimum', font: fontBold, color: pdfWhite),
                      _tableCell('Maximum', font: fontBold, color: pdfWhite),
                    ],
                  ),
                  // Temperature Row
                  pw.TableRow(
                    children: [
                      _tableCell('Temperature (°C)', font: fontBold),
                      _tableCell(latestTemp != null ? '${latestTemp.toStringAsFixed(1)} °C' : '—', font: fontRegular),
                      _tableCell(avgTemp != null ? '${avgTemp.toStringAsFixed(1)} °C' : '—', font: fontRegular),
                      _tableCell(minTemp != null ? '${minTemp.toStringAsFixed(1)} °C' : '—', font: fontRegular),
                      _tableCell(maxTemp != null ? '${maxTemp.toStringAsFixed(1)} °C' : '—', font: fontRegular),
                    ],
                  ),
                  // Humidity Row
                  pw.TableRow(
                    children: [
                      _tableCell('Humidity (%)', font: fontBold),
                      _tableCell(latestHum != null ? '${latestHum.toStringAsFixed(1)} %' : '—', font: fontRegular),
                      _tableCell(avgHum != null ? '${avgHum.toStringAsFixed(1)} %' : '—', font: fontRegular),
                      _tableCell(minHum != null ? '${minHum.toStringAsFixed(1)} %' : '—', font: fontRegular),
                      _tableCell(maxHum != null ? '${maxHum.toStringAsFixed(1)} %' : '—', font: fontRegular),
                    ],
                  ),
                  // MQ135 Row
                  pw.TableRow(
                    children: [
                      _tableCell('MQ135 (RAW ADC)', font: fontBold),
                      _tableCell(latestMq != null ? '$latestMq raw' : '—', font: fontRegular),
                      _tableCell(avgMq != null ? '$avgMq raw' : '—', font: fontRegular),
                      _tableCell(minMq != null ? '$minMq raw' : '—', font: fontRegular),
                      _tableCell(maxMq != null ? '$maxMq raw' : '—', font: fontRegular),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // ── 4. STATUS DISTRIBUTION ─────────────────────────────────────
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: pdfWhite,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: pdfGoldfinch, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'NORMAL Readings',
                            style: pw.TextStyle(font: fontBold, fontSize: 10, color: pdfGoldfinch),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '$normalCount ($normalPct%)',
                            style: pw.TextStyle(font: fontBold, fontSize: 16, color: pdfBistro),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: pdfWhite,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: pdfIndianRed, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'POOR Readings',
                            style: pw.TextStyle(font: fontBold, fontSize: 10, color: pdfIndianRed),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '$poorCount ($poorPct%)',
                            style: pw.TextStyle(font: fontBold, fontSize: 16, color: pdfBistro),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // ── 5. EXPLICIT DISCLAIMER ──────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFF8EE'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: pdfGoldfinch, width: 0.6),
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 4,
                      height: 32,
                      color: pdfGoldfinch,
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Text(
                        'Disclaimer: The MQ135 value shown here is a raw sensor reading used by this prototype\'s threshold-based classification. It is not an official AQI or ppm measurement.',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 9,
                          color: pdfBistro,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ── 6. TREND BREAKDOWN ──────────────────────────────────────────
              pw.Text(
                'Recent Readings Trend',
                style: pw.TextStyle(font: fontBold, fontSize: 13, color: pdfBistro),
              ),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E8E0D5'), width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F2ECE4')),
                    children: [
                      _tableCell('Time', font: fontBold),
                      _tableCell('Temp (°C)', font: fontBold),
                      _tableCell('Humidity (%)', font: fontBold),
                      _tableCell('MQ135 (Raw)', font: fontBold),
                      _tableCell('Status', font: fontBold),
                    ],
                  ),
                  ...dataList.take(8).map((item) {
                    final timeStr = DateFormat('HH:mm:ss').format(item.timestamp);
                    return pw.TableRow(
                      children: [
                        _tableCell(timeStr, font: fontRegular),
                        _tableCell(item.temperature != null ? '${item.temperature!.toStringAsFixed(1)}°C' : '—', font: fontRegular),
                        _tableCell(item.humidity != null ? '${item.humidity!.toStringAsFixed(1)}%' : '—', font: fontRegular),
                        _tableCell(item.mq135Raw != null ? '${item.mq135Raw}' : '—', font: fontRegular),
                        _tableCell(
                          item.statusLabel,
                          font: fontBold,
                          color: item.isPoor ? pdfGarnet : pdfGoldfinch,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.Spacer(),

              // ── FOOTER ─────────────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColor.fromHex('#E8E0D5'), width: 0.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'AirSense Smart Environmental Monitoring System',
                      style: pw.TextStyle(font: fontRegular, fontSize: 8, color: pdfTextMuted),
                    ),
                    pw.Text(
                      'Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}',
                      style: pw.TextStyle(font: fontRegular, fontSize: 8, color: pdfTextMuted),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _tableCell(
    String text, {
    required pw.Font font,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 9,
          color: color ?? pdfBistro,
        ),
      ),
    );
  }
}
