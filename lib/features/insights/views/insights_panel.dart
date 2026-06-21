import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/insight.dart';
import '../providers/insight_providers.dart';

class InsightsPanel extends ConsumerWidget {
  const InsightsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actionable Insights'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Card
                _buildSummaryHeader(theme),
                const SizedBox(height: 24),

                Text(
                  'Recommended Actions',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                insightsAsync.when(
                  data: (insights) {
                    if (insights.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                            'No insights available yet. Try logging more days.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: insights.map((insight) => _buildInsightCard(theme, insight)).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text(
                        'Failed to load insights. $error',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(ThemeData theme) {
    return Card(
      color: AppColors.secondary.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Insights Engine Active',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We analyze your logged transport, diet, and energy metrics to suggest personalized carbon savings.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(ThemeData theme, Insight insight) {
    IconData icon;
    Color catColor;

    switch (insight.category) {
      case 'transport':
        icon = Icons.directions_car_outlined;
        catColor = AppColors.primary;
        break;
      case 'diet':
        icon = Icons.restaurant_outlined;
        catColor = AppColors.secondary;
        break;
      case 'energy':
        icon = Icons.bolt_outlined;
        catColor = AppColors.tertiary;
        break;
      default:
        icon = Icons.eco_outlined;
        catColor = AppColors.success;
    }

    Color priorityColor;
    switch (insight.priority) {
      case InsightPriority.high:
        priorityColor = AppColors.error;
        break;
      case InsightPriority.medium:
        priorityColor = AppColors.warning;
        break;
      case InsightPriority.low:
        priorityColor = AppColors.info;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Category Icon, Priority and savings badge
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: catColor.withOpacity(0.1),
                  child: Icon(icon, color: catColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.category.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: catColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              insight.priority.displayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: priorityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${insight.potentialSavingsKg.toStringAsFixed(1)} kg CO₂e',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              insight.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              insight.description,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
