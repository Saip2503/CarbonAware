import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/co2_calculator.dart';
import '../../../logging/domain/daily_log.dart';

class CategoryBreakdown extends StatelessWidget {
  final List<DailyLog> logs;

  const CategoryBreakdown({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double totalTransport = 0.0;
    double totalDiet = 0.0;
    double totalEnergy = 0.0;

    for (var log in logs) {
      totalTransport += CO2Calculator.calculateTransport(log.transportDistance, log.vehicleType, isKm: log.isKm);
      totalDiet += CO2Calculator.calculateDiet(log.dietType);
      totalEnergy += CO2Calculator.calculateEnergy(log.electricityKwh);
    }

    final double grandTotal = totalTransport + totalDiet + totalEnergy;

    if (grandTotal <= 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pie_chart_outline, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                'No data logged yet.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final pTransport = (totalTransport / grandTotal) * 100;
    final pDiet = (totalDiet / grandTotal) * 100;
    final pEnergy = (totalEnergy / grandTotal) * 100;

    String highestCategory = 'None';
    double maxVal = 0.0;
    if (totalTransport > maxVal) {
      maxVal = totalTransport;
      highestCategory = 'Transport (${pTransport.toStringAsFixed(1)}%)';
    }
    if (totalDiet > maxVal) {
      maxVal = totalDiet;
      highestCategory = 'Diet (${pDiet.toStringAsFixed(1)}%)';
    }
    if (totalEnergy > maxVal) {
      maxVal = totalEnergy;
      highestCategory = 'Energy (${pEnergy.toStringAsFixed(1)}%)';
    }
    final semanticsLabel = 'Donut chart showing emissions breakdown: Transport is ${totalTransport.toStringAsFixed(1)} kg (${pTransport.toStringAsFixed(1)}%), Diet is ${totalDiet.toStringAsFixed(1)} kg (${pDiet.toStringAsFixed(1)}%), Energy is ${totalEnergy.toStringAsFixed(1)} kg (${pEnergy.toStringAsFixed(1)}%). The highest source of emissions is $highestCategory.';

    return Semantics(
      label: semanticsLabel,
      child: Row(
        children: [
          // Pie Chart
          Expanded(
            flex: 2,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 35,
                  sections: [
                    if (totalTransport > 0)
                      PieChartSectionData(
                        color: AppColors.primary,
                        value: totalTransport,
                        title: '${pTransport.toStringAsFixed(0)}%',
                        radius: 30,
                        titleStyle: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (totalDiet > 0)
                      PieChartSectionData(
                        color: AppColors.secondary,
                        value: totalDiet,
                        title: '${pDiet.toStringAsFixed(0)}%',
                        radius: 30,
                        titleStyle: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (totalEnergy > 0)
                      PieChartSectionData(
                        color: AppColors.tertiary,
                        value: totalEnergy,
                        title: '${pEnergy.toStringAsFixed(0)}%',
                        radius: 30,
                        titleStyle: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Legends
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(
                  theme, 
                  color: AppColors.primary, 
                  label: 'Transport', 
                  value: totalTransport, 
                  percentage: pTransport,
                ),
                const SizedBox(height: 12),
                _buildLegendItem(
                  theme, 
                  color: AppColors.secondary, 
                  label: 'Diet', 
                  value: totalDiet, 
                  percentage: pDiet,
                ),
                const SizedBox(height: 12),
                _buildLegendItem(
                  theme, 
                  color: AppColors.tertiary, 
                  label: 'Energy', 
                  value: totalEnergy, 
                  percentage: pEnergy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    ThemeData theme, {
    required Color color,
    required String label,
    required double value,
    required double percentage,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)} kg CO₂e (${percentage.toStringAsFixed(1)}%)',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
