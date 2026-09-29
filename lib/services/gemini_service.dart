import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/sensor_data.dart';

class GeminiExplanationResult {
  final String? text;
  final String? errorMessage;

  const GeminiExplanationResult({this.text, this.errorMessage});

  bool get isSuccess => text != null && text!.isNotEmpty;
  bool get hasError => errorMessage != null;
}

class GeminiService {
  /// Supported Gemini models to try in order of preference
  static const List<String> _modelsToTry = [
    'gemini-2.5-flash',
    'gemini-flash-latest',
    'gemini-1.5-flash',
  ];

  /// Explain sensor readings using Google Gemini API
  static Future<GeminiExplanationResult> explainReadings({
    required SensorData latest,
    required List<SensorData> history,
  }) async {
    final apiKey = AppConfig.geminiApiKey.trim();

    if (apiKey.isEmpty) {
      return const GeminiExplanationResult(
        errorMessage:
            'Gemini API key is not configured. Please set static const String geminiApiKey in lib/config/app_config.dart or pass --dart-define=GEMINI_API_KEY=your_key.',
      );
    }

    final tempStr = latest.temperature != null
        ? '${latest.temperature!.toStringAsFixed(1)}°C'
        : 'N/A';
    final humStr = latest.humidity != null
        ? '${latest.humidity!.toStringAsFixed(1)}%'
        : 'N/A';
    final mqStr = latest.mq135Raw?.toString() ?? 'N/A';
    final statusStr = latest.statusLabel;

    final promptText = '''
Provide a clear 3-bullet explanation of these environmental sensor readings:
- Temperature: $tempStr
- Humidity: $humStr
- MQ135 Raw ADC Reading: $mqStr
- Overall Status: $statusStr

INSTRUCTIONS:
1. Bullet 1: Explain temperature ($tempStr) and humidity ($humStr) in simple, friendly terms.
2. Bullet 2: Include this exact sentence verbatim:
"The MQ135 value shown here is a raw sensor reading used by this prototype's threshold-based classification. It is not an official AQI or ppm measurement."
3. Bullet 3: Explain what the raw reading ($mqStr) and the status ($statusStr) mean for a normal user.
4. Each bullet point MUST be a complete sentence ending with proper punctuation.
''';

    String? lastError;

    for (final modelName in _modelsToTry) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
        );

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': promptText}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.3,
              'maxOutputTokens': 800,
            }
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = json['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              String text = parts[0]['text']?.toString().trim() ?? '';
              if (text.isNotEmpty) {
                // Ensure text ends cleanly at a complete sentence
                final lastPunctuation = text.lastIndexOf(RegExp(r'[.!?]'));
                if (lastPunctuation != -1 && lastPunctuation < text.length - 1) {
                  text = text.substring(0, lastPunctuation + 1);
                }
                return GeminiExplanationResult(text: text);
              }
            }
          }
        } else {
          final json = jsonDecode(response.body) as Map<String, dynamic>?;
          lastError = json?['error']?['message']?.toString() ??
              'Model $modelName returned HTTP ${response.statusCode}';
        }
      } catch (e) {
        lastError = 'Connection error with $modelName: ${e.toString()}';
      }
    }

    return GeminiExplanationResult(
      errorMessage: lastError ?? 'Failed to reach Gemini API.',
    );
  }
}
