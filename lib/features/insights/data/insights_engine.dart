import '../../../core/constants/emission_factors.dart';
import '../../../core/utils/co2_calculator.dart';
import '../../logging/models/daily_log.dart';
import '../models/insight.dart';

class InsightsEngine {
  static List<Insight> generateInsights(List<DailyLog> logs) {
    final List<Insight> insights = [];

    if (logs.isEmpty) {
      // Default placeholder insights for onboarding
      insights.add(Insight(
        title: 'Start Logging Today',
        description: 'Log your daily activities in the transport, diet, and energy categories to unlock hyper-personalized, AI-driven carbon-saving recommendations.',
        category: 'general',
        potentialSavingsKg: 5.0,
        priority: InsightPriority.high,
      ));
      insights.add(Insight(
        title: 'Adopt a Plant-Based Meal',
        description: 'Did you know? Vegetarian meals generate about 47% fewer emissions than meat-heavy ones. Start with one green day a week.',
        category: 'diet',
        potentialSavingsKg: 3.38, // 7.19 - 3.81
        priority: InsightPriority.medium,
      ));
      return insights;
    }

    // Aggregate statistics
    double totalTransport = 0.0;
    double totalDiet = 0.0;
    double totalEnergy = 0.0;
    double totalMiles = 0.0;
    int carDays = 0;
    int meatHeavyDays = 0;
    int logCount = logs.length;

    for (var log in logs) {
      totalTransport += CO2Calculator.calculateTransport(log.transportMiles, log.vehicleType);
      totalDiet += CO2Calculator.calculateDiet(log.dietType);
      totalEnergy += CO2Calculator.calculateEnergy(log.electricityKwh);
      totalMiles += log.transportMiles;
      
      if (log.vehicleType == VehicleType.car && log.transportMiles > 0) {
        carDays++;
      }
      if (log.dietType == DietType.meatHeavy) {
        meatHeavyDays++;
      }
    }

    final double avgTransport = totalTransport / logCount;
    final double avgDiet = totalDiet / logCount;
    final double avgEnergy = totalEnergy / logCount;
    final double avgMiles = totalMiles / logCount;

    // 1. Dynamic Transport Insight
    if (carDays > 0 && avgMiles > 0) {
      // Suggest switching some trips to transit or active transport (e.g. bike/walk)
      final double halfCommuteSavings = (avgMiles / 2) * (kCarEmission - kBusEmission);
      final double activeCommuteSavings = (avgMiles / 2) * kCarEmission; // savings if walk/bike

      if (activeCommuteSavings > 3.0) {
        insights.add(Insight(
          title: 'Walk or Cycle for Short Trips',
          description: 'You logged average car travel of ${avgMiles.toStringAsFixed(1)} miles. Replacing half of those miles with walking or bicycling saves ${activeCommuteSavings.toStringAsFixed(1)} kg CO₂e.',
          category: 'transport',
          potentialSavingsKg: activeCommuteSavings,
          priority: activeCommuteSavings > 8.0 ? InsightPriority.high : InsightPriority.medium,
        ));
      }

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

    // 2. Dynamic Diet Insight
    if (meatHeavyDays > 0) {
      // Suggest vegetarian or vegan days
      final double vegSavings = kMeatHeavyDiet - kVegetarianDiet;
      final double veganSavings = kMeatHeavyDiet - kVeganDiet;

      insights.add(Insight(
        title: 'Switch to a Vegetarian Lunch',
        description: 'Replacing meat-heavy meals with vegetarian options tomorrow saves ${vegSavings.toStringAsFixed(1)} kg CO₂e.',
        category: 'diet',
        potentialSavingsKg: vegSavings,
        priority: vegSavings > 3.0 ? InsightPriority.high : InsightPriority.medium,
      ));

      insights.add(Insight(
        title: 'Try a Fully Plant-Based Day',
        description: 'Going entirely vegan for one day eliminates animal agriculture emissions, saving you ${veganSavings.toStringAsFixed(1)} kg CO₂e compared to a meat-heavy day.',
        category: 'diet',
        potentialSavingsKg: veganSavings,
        priority: InsightPriority.high,
      ));
    } else if (avgDiet > kVeganDiet + 0.5) {
      // If average diet is average/vegetarian, suggest upgrading to vegan sometimes
      final double savings = avgDiet - kVeganDiet;
      insights.add(Insight(
        title: 'Explore Vegan Alternatives',
        description: 'Swapping cheese, milk, or eggs for plant-based alternatives today saves ${savings.toStringAsFixed(1)} kg CO₂e.',
        category: 'diet',
        potentialSavingsKg: savings,
        priority: InsightPriority.low,
      ));
    }

    // 3. Dynamic Energy Insight
    final double avgKwh = (logs.map((l) => l.electricityKwh).reduce((a, b) => a + b)) / logCount;
    if (avgKwh > 10.0) {
      // Suggest 15% reduction in electricity
      final double targetSavingsKwh = avgKwh * 0.15;
      final double energySavings = targetSavingsKwh * kElectricityEmission;

      insights.add(Insight(
        title: 'Unplug Standby Appliances',
        description: 'Reducing standby power consumption by 15% (saving ${targetSavingsKwh.toStringAsFixed(1)} kWh) saves ${energySavings.toStringAsFixed(1)} kg CO₂e daily.',
        category: 'energy',
        potentialSavingsKg: energySavings,
        priority: energySavings > 3.0 ? InsightPriority.high : InsightPriority.medium,
      ));
      
      insights.add(Insight(
        title: 'Optimize Heating & Cooling',
        description: 'Adjusting your thermostat by 1-2°C can easily shave off 3 kWh from your daily usage, saving ${(3 * kElectricityEmission).toStringAsFixed(1)} kg CO₂e.',
        category: 'energy',
        potentialSavingsKg: 3 * kElectricityEmission,
        priority: InsightPriority.medium,
      ));
    }

    // Sort insights by highest savings first (impactful prioritization)
    insights.sort((a, b) => b.potentialSavingsKg.compareTo(a.potentialSavingsKg));

    return insights;
  }
}
