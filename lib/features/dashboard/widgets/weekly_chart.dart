import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../logging/models/daily_log.dart';

class WeeklyChart extends StatelessWidget {
  final List<DailyLog> logs;
  final double dailyGoal;

  const WeeklyChart({
    super.key,
    required this.logs,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Generate last 7 days list if logs don't cover all days
    final now = DateTime.now();
    final Map<String, DailyLog?> logMap = {
      for (var log in logs) log.date: log
    };

    final List<MapEntry<String, double>> chartData = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final log = logMap[dateStr];
      chartData.add(MapEntry(
        DateFormat('E').format(date), // E.g., Mon, Tue
        log?.totalCO2Kg ?? 0.0,
      ));
    }

    // Find max value to scale chart properly
    double maxVal = dailyGoal * 1.5;
    for (var entry in chartData) {
      if (entry.value > maxVal) {
        maxVal = entry.value;
      }
    }
    maxVal = maxVal <= 0 ? 10.0 : maxVal;

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.1,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              tooltipBorder: const BorderSide(color: AppColors.glassBorder),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final dateStr = chartData[groupIndex].key;
                final val = rod.toY;
                return BarTooltipItem(
                  '$dateStr\n',
                  theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '${val.toStringAsFixed(1)} kg',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: val > dailyGoal ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < chartData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        chartData[index].key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('');
                  return Text(
                    value.toStringAsFixed(0),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: dailyGoal / 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.glassBorder.withOpacity(0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: dailyGoal,
                color: AppColors.tertiary,
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                  labelResolver: (line) => 'Goal (${dailyGoal.toStringAsFixed(1)})',
                ),
              ),
            ],
          ),
          barGroups: List.generate(chartData.length, (index) {
            final val = chartData[index].value;
            final isOverGoal = val > dailyGoal;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: isOverGoal ? AppColors.error : AppColors.primary,
                  width: 16,
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxVal * 1.1,
                    color: AppColors.glassBorder.withOpacity(0.03),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
