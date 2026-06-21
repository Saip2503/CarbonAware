import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_providers.dart';

class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  double _weeklyGoal = 47.6; // Default to 6.8 * 7
  bool _isLoading = false;

  Future<void> _saveGoal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final uid = authRepo.currentUid;
      if (uid != null) {
        // Store daily budget = weekly / 7
        final dailyGoal = _weeklyGoal / 7.0;
        await authRepo.updateUserGoalAndOnboardStatus(uid, dailyGoal);
        
        // Invalidate user profile to force reload state
        ref.invalidate(userProfileProvider);
        
        if (mounted) {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save goal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dailyEquivalent = _weeklyGoal / 7.0;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.track_changes_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Set Your Target',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Onboarding: Choose your weekly carbon budget goal. We will track your progress against this baseline.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                Card(
                  color: AppColors.cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'WEEKLY BUDGET TARGET',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _weeklyGoal.toStringAsFixed(1),
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'kg CO₂e',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Daily average equivalent: ${dailyEquivalent.toStringAsFixed(1)} kg CO₂e',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          label: 'Weekly Carbon Goal Slider',
                          child: Slider(
                            value: _weeklyGoal,
                            min: 10.0,
                            max: 150.0,
                            divisions: 140,
                            activeColor: AppColors.primary,
                            inactiveColor: AppColors.glassBorder,
                            onChanged: (val) {
                              setState(() {
                                _weeklyGoal = val;
                              });
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('10 kg (Highly Green)', style: theme.textTheme.bodySmall),
                            Text('150 kg (Avg. Footprint)', style: theme.textTheme.bodySmall),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Comparison info
                _buildComparisonCard(theme),
                const SizedBox(height: 32),

                // Action Button
                Semantics(
                  label: 'Set Goal and Proceed Button',
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveGoal,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirm Goal & Enter App'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonCard(ThemeData theme) {
    String message;
    IconData icon;
    Color color;

    if (_weeklyGoal < 30.0) {
      message = 'Extremely ambitious! This is close to the absolute minimum necessary for long-term ecological sustainability.';
      icon = Icons.eco;
      color = AppColors.success;
    } else if (_weeklyGoal <= 50.0) {
      message = 'Eco-friendly target. This aligns with recommended global carbon reduction benchmarks (less than 7 kg/day).';
      icon = Icons.verified_user_outlined;
      color = AppColors.primary;
    } else if (_weeklyGoal <= 90.0) {
      message = 'Moderate target. A good starting point to start optimizing and reducing your emissions.';
      icon = Icons.info_outline;
      color = AppColors.warning;
    } else {
      message = 'Above benchmark. Aim lower over time to challenge yourself and maximize your environmental contribution!';
      icon = Icons.warning_amber_rounded;
      color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
