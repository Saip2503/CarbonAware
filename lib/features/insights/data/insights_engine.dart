import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/constants/emission_factors.dart';
import '../../../core/utils/co2_calculator.dart';
import '../../logging/models/daily_log.dart';
import '../models/insight.dart';

class InsightsEngine {
  static Future<List<Insight>> generateInsights(List<DailyLog> logs) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      // Fallback to basic insights if API key is not configured
      return _generateBasicInsights(logs);
    }

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      
      // Prepare log data for the prompt
      final logsData = logs.map((l) => {
        'date': l.date,
        'transportMiles': l.transportMiles,
        'vehicleType': l.vehicleType.name,
        'dietType': l.dietType.name,
        'electricityKwh': l.electricityKwh,
      }).toList();

      final prompt = '''
      You are an AI assistant for a carbon footprint tracking app.
      Analyze the following daily logs of a user and provide exactly 3 actionable insights to reduce their carbon footprint.
      
      Logs:
      ${jsonEncode(logsData)}

      Emission Factors reference:
      - Car: $kCarEmission kg CO2/mile
      - Bus: $kBusEmission kg CO2/mile
      - Meat Heavy Diet: $kMeatHeavyDiet kg CO2/day
      - Average Diet: $kAverageDiet kg CO2/day
      - Vegetarian Diet: $kVegetarianDiet kg CO2/day
      - Vegan Diet: $kVeganDiet kg CO2/day
      - Electricity: $kElectricityEmission kg CO2/kWh
      
      Return a JSON array of objects with the following keys:
      - "title": A short, catchy title (e.g., "Walk or Cycle for Short Trips")
      - "description": A clear description of the action and its benefits.
      - "category": One of "transport", "diet", "energy", "general".
      - "potentialSavingsKg": Estimated daily CO2 savings in kg (number).
      - "priority": One of "high", "medium", "low".
      
      Respond ONLY with valid JSON. Do not include markdown formatting or backticks.
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        String responseText = response.text!.trim();
        if (responseText.startsWith('```json')) {
          responseText = responseText.replaceAll('```json', '');
          responseText = responseText.replaceAll('```', '');
        } else if (responseText.startsWith('```')) {
          responseText = responseText.replaceAll('```', '');
        }
        
        final List<dynamic> jsonList = jsonDecode(responseText.trim());
        
        return jsonList.map((json) {
          InsightPriority priority;
          switch (json['priority']) {
            case 'high':
              priority = InsightPriority.high;
              break;
            case 'low':
              priority = InsightPriority.low;
              break;
            default:
              priority = InsightPriority.medium;
          }
          
          return Insight(
            title: json['title'] ?? 'Insight',
            description: json['description'] ?? '',
            category: json['category'] ?? 'general',
            potentialSavingsKg: (json['potentialSavingsKg'] as num?)?.toDouble() ?? 0.0,
            priority: priority,
          );
        }).toList();
      }
    } catch (e) {
      print('Error generating AI insights: $e');
    }

    return _generateBasicInsights(logs);
  }

  static List<Insight> _generateBasicInsights(List<DailyLog> logs) {
    final List<Insight> insights = [];

    if (logs.isEmpty) {
      insights.add(Insight(
        title: 'Start Logging Today',
        description: 'Log your daily activities in the transport, diet, and energy categories to unlock hyper-personalized, AI-driven carbon-saving recommendations.',
        category: 'general',
        potentialSavingsKg: 5.0,
        priority: InsightPriority.high,
      ));
      return insights;
    }

    double totalDiet = 0.0;
    double totalMiles = 0.0;
    int carDays = 0;
    int meatHeavyDays = 0;
    int logCount = logs.length;

    for (var log in logs) {
      totalDiet += CO2Calculator.calculateDiet(log.dietType);
      totalMiles += log.transportMiles;
      
      if (log.vehicleType == VehicleType.car && log.transportMiles > 0) {
        carDays++;
      }
      if (log.dietType == DietType.meatHeavy) {
        meatHeavyDays++;
      }
    }

    final double avgMiles = totalMiles / logCount;

    if (carDays > 0 && avgMiles > 0) {
      final double halfCommuteSavings = (avgMiles / 2) * (kCarEmission - kBusEmission);
      if (halfCommuteSavings > 1.5) {
        insights.add(Insight(
          title: 'Try Public Transit',
          description: 'Switching half of your daily car travel (${(avgMiles / 2).toStringAsFixed(1)} miles) to bus/public transport saves ${halfCommuteSavings.toStringAsFixed(1)} kg CO₂e.',
          category: 'transport',
          potentialSavingsKg: halfCommuteSavings,
          priority: halfCommuteSavings > 5.0 ? InsightPriority.high : InsightPriority.medium,
        ));
      }
    }

    if (meatHeavyDays > 0) {
      final double vegSavings = kMeatHeavyDiet - kVegetarianDiet;
      insights.add(Insight(
        title: 'Switch to a Vegetarian Lunch',
        description: 'Replacing meat-heavy meals with vegetarian options tomorrow saves ${vegSavings.toStringAsFixed(1)} kg CO₂e.',
        category: 'diet',
        potentialSavingsKg: vegSavings,
        priority: vegSavings > 3.0 ? InsightPriority.high : InsightPriority.medium,
      ));
    }

    return insights;
  }
}
