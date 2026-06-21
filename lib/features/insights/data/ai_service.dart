import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../logging/models/daily_log.dart';
import '../models/insight.dart';
import 'insights_engine.dart';

class AiService {
  static Future<Insight> generateAiInsight(List<DailyLog> logs) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    // Fallback if API key is not configured or is a placeholder
    if (apiKey == null || 
        apiKey.isEmpty || 
        apiKey == 'YOUR_GEMINI_API_KEY_HERE' || 
        apiKey.startsWith('placeholder')) {
      debugPrint("AiService: Gemini API key not configured or is placeholder. Using rule-based fallback.");
      return _generateFallbackInsight(logs);
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      // Build data summary for prompt
      final logsSummary = logs.map((log) {
        return '- Date: ${log.date}, Transport: ${log.transportMiles} miles (${log.vehicleType.displayName}), Diet: ${log.dietType.displayName}, Energy: ${log.electricityKwh} kWh, Total CO2: ${log.totalCO2Kg.toStringAsFixed(1)} kg';
      }).join('\n');

      final prompt = '''
You are CarbonAware AI, a helpful, professional sustainability assistant.
Analyze the user's carbon footprint data for the last 7 days:
$logsSummary

Please identify the highest emission category (transport, diet, or energy) and generate a single, highly personalized, actionable tip to reduce their footprint.

Your response must strictly follow this format (5 lines):
Title: <A catchy, short title under 6 words>
Category: <exactly one of: transport, diet, energy>
Estimated Savings: <a number representing daily/weekly savings in kg CO2e, e.g. 3.5>
Priority: <exactly one of: high, medium, low>
Tip: <A concise, encouraging, and actionable tip under 30 words>

Do not include any other text, markdown formatting, or bullet points. Just the 5 lines.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        throw Exception("Empty response from Gemini");
      }

      return _parseResponse(text, logs);
    } catch (e) {
      debugPrint("AiService Error: $e. Falling back to rule-based insight.");
      return _generateFallbackInsight(logs);
    }
  }

  static Insight _parseResponse(String text, List<DailyLog> logs) {
    try {
      final lines = text.split('\n');
      String title = 'Save Carbon Today';
      String category = 'general';
      double savings = 2.0;
      InsightPriority priority = InsightPriority.medium;
      String tip = 'Continue tracking your activities daily to discover more ways to reduce emissions.';

      for (var line in lines) {
        final lowerLine = line.toLowerCase();
        if (lowerLine.startsWith('title:')) {
          title = line.substring(6).trim();
        } else if (lowerLine.startsWith('category:')) {
          final cat = line.substring(9).trim().toLowerCase();
          if (['transport', 'diet', 'energy'].contains(cat)) {
            category = cat;
          }
        } else if (lowerLine.startsWith('estimated savings:')) {
          final val = line.substring(18).trim();
          savings = double.tryParse(val) ?? 2.0;
        } else if (lowerLine.startsWith('priority:')) {
          final prioStr = line.substring(9).trim().toLowerCase();
          if (prioStr.contains('high')) {
            priority = InsightPriority.high;
          } else if (prioStr.contains('low')) {
            priority = InsightPriority.low;
          } else {
            priority = InsightPriority.medium;
          }
        } else if (lowerLine.startsWith('tip:')) {
          tip = line.substring(4).trim();
        }
      }

      return Insight(
        title: title,
        description: tip,
        category: category,
        potentialSavingsKg: savings,
        priority: priority,
      );
    } catch (e) {
      debugPrint("AiService: Failed to parse Gemini response: $e");
      return _generateFallbackInsight(logs);
    }
  }

  static Insight _generateFallbackInsight(List<DailyLog> logs) {
    // Generate insights using our rule-based engine and return the top one
    final ruleBasedInsights = InsightsEngine.generateInsights(logs);
    if (ruleBasedInsights.isNotEmpty) {
      return ruleBasedInsights.first;
    }
    return Insight(
      title: 'Reduce Standby Power',
      description: 'Unplugging electronics like TVs, game consoles, and chargers when not in use can shave up to 10% off your energy footprint.',
      category: 'energy',
      potentialSavingsKg: 1.5,
      priority: InsightPriority.low,
    );
  }
}
