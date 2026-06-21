import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class GoalIndicator extends StatelessWidget {
  final double todayValue;
  final double dailyGoal;

  const GoalIndicator({
    super.key,
    required this.todayValue,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = dailyGoal > 0 ? (todayValue / dailyGoal) : 0.0;
    
    // Choose status color based on ratio
    Color progressColor;
    String statusText;
    if (ratio < 0.8) {
      progressColor = AppColors.success;
      statusText = 'On Track';
    } else if (ratio <= 1.0) {
      progressColor = AppColors.warning;
      statusText = 'Approaching Limit';
    } else {
      progressColor = AppColors.error;
      statusText = 'Exceeded Goal';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Background track
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 12,
                color: AppColors.glassBorder.withOpacity(0.05),
              ),
            ),
            // Progress arc
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                strokeWidth: 12,
                color: progressColor,
                strokeCap: StrokeCap.round,
              ),
            ),
            // Middle stats
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  todayValue.toStringAsFixed(1),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '/ ${dailyGoal.toStringAsFixed(1)} kg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: progressColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: progressColor.withOpacity(0.3), width: 1.0),
          ),
          child: Text(
            statusText,
            style: theme.textTheme.labelLarge?.copyWith(
              color: progressColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
