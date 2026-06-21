import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_aware/features/insights/data/insights_engine.dart';
import 'package:carbon_aware/features/insights/models/insight.dart';
import 'package:carbon_aware/features/logging/models/daily_log.dart';
import 'package:carbon_aware/core/utils/co2_calculator.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'GEMINI_API_KEY=mock_key');
  });

  group('InsightsEngine Fallback Rule-Based Tests', () {
    test('returns Start Logging Today insight when log list is empty', () async {
      final insights = await InsightsEngine.generateInsights([]);

      expect(insights.length, 1);
      expect(insights.first.title, 'Start Logging Today');
      expect(insights.first.category, 'general');
      expect(insights.first.priority, InsightPriority.high);
    });

    test('recommends public transit when car transport emissions are high', () async {
      final logs = [
        DailyLog(
          date: '2026-06-21',
          transportMiles: 20.0, // High miles
          vehicleType: VehicleType.car,
          dietType: DietType.vegetarian,
          electricityKwh: 2.0,
          totalCO2Kg: 5.0,
          timestamp: DateTime(2026, 6, 21),
        ),
      ];

      final insights = await InsightsEngine.generateInsights(logs);

      // Should have public transit advice
      final transitInsight = insights.firstWhere((i) => i.category == 'transport');
      expect(transitInsight.title, 'Try Public Transit');
      expect(transitInsight.potentialSavingsKg, greaterThan(1.5));
    });

    test('recommends vegetarian lunch when diet is meat-heavy', () async {
      final logs = [
        DailyLog(
          date: '2026-06-21',
          transportMiles: 0.0,
          vehicleType: VehicleType.walk,
          dietType: DietType.meatHeavy,
          electricityKwh: 2.0,
          totalCO2Kg: 5.0,
          timestamp: DateTime(2026, 6, 21),
        ),
      ];

      final insights = await InsightsEngine.generateInsights(logs);

      // Should have vegetarian diet advice
      final dietInsight = insights.firstWhere((i) => i.category == 'diet');
      expect(dietInsight.title, 'Switch to a Vegetarian Lunch');
      expect(dietInsight.potentialSavingsKg, greaterThan(0.0));
    });

    test('provides multiple insights when both transport and diet are improvable', () async {
      final logs = [
        DailyLog(
          date: '2026-06-21',
          transportMiles: 20.0,
          vehicleType: VehicleType.car,
          dietType: DietType.meatHeavy,
          electricityKwh: 2.0,
          totalCO2Kg: 10.0,
          timestamp: DateTime(2026, 6, 21),
        ),
      ];

      final insights = await InsightsEngine.generateInsights(logs);

      expect(insights.any((i) => i.category == 'transport'), isTrue);
      expect(insights.any((i) => i.category == 'diet'), isTrue);
    });
  });
}
