import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../logging/presentation/providers/log_providers.dart';
import '../../../insights/presentation/views/insight_card.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/goal_indicator.dart';
import '../widgets/weekly_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Auth & Profile states
    final profileAsync = ref.watch(userProfileProvider);
    final logsAsync = ref.watch(recentLogsStreamProvider);
    
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.eco_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'CarbonAware',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          profileAsync.when(
            data: (profile) => profile != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Center(
                      child: Text(
                        'Hi, ${profile.displayName.split(' ')[0]}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => _confirmSignOut(context, ref),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentLogsStreamProvider);
          ref.invalidate(userProfileProvider);
          ref.invalidate(todaysLogProvider);
        },
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found. Please log in again.'));
            }

            final dailyGoal = profile.dailyGoalKgCO2;

            return logsAsync.when(
              data: (logs) {
                // Find today's log in the logs list
                final todayLog = logs.where((l) => l.date == todayStr).firstOrNull;
                final todayVal = todayLog?.totalCO2Kg ?? 0.0;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Goal Indicator & Action Row
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 550) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                                          child: GoalIndicator(
                                            todayValue: todayVal,
                                            dailyGoal: dailyGoal,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildWelcomeLogCard(context, todayLog != null, theme),
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    Card(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                                        child: Center(
                                          child: GoalIndicator(
                                            todayValue: todayVal,
                                            dailyGoal: dailyGoal,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildWelcomeLogCard(context, todayLog != null, theme),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          // AI Assistant Smart Tips Card
                          const InsightCard(),
                          const SizedBox(height: 20),

                          // Weekly Chart
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Weekly Emissions',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  WeeklyChart(logs: logs, dailyGoal: dailyGoal),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Category Breakdown
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emission Sources',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CategoryBreakdown(logs: logs),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading logs: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading profile: $err')),
        ),
      ),
    );
  }

  Widget _buildWelcomeLogCard(BuildContext context, bool loggedToday, ThemeData theme) {
    return Card(
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loggedToday ? 'You are logged for today!' : 'Keep your habits updated',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loggedToday
                  ? 'Great job! You can edit today\'s log anytime by tapping the log button.'
                  : 'Frictionless logging keeps you aware of your footprint. Log transportation, diet, and energy now.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/log'),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: Text(loggedToday ? 'Edit Log' : 'Quick-Log Today'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out of CarbonAware?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }
}
