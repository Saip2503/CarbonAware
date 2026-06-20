import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/co2_calculator.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/daily_log.dart';
import '../providers/log_providers.dart';

class QuickLogScreen extends ConsumerStatefulWidget {
  const QuickLogScreen({super.key});

  @override
  ConsumerState<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends ConsumerState<QuickLogScreen> {
  double _transportMiles = 0.0;
  VehicleType _vehicleType = VehicleType.car;
  DietType _dietType = DietType.average;
  double _electricityKwh = 0.0;
  bool _isLoading = false;
  bool _isInit = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    // Watch today's log if it has been loaded
    final todaysLogAsync = ref.watch(todaysLogProvider);

    todaysLogAsync.whenData((log) {
      if (log != null && !_isInit) {
        setState(() {
          _transportMiles = log.transportMiles;
          _vehicleType = log.vehicleType;
          _dietType = log.dietType;
          _electricityKwh = log.electricityKwh;
          _isInit = true;
        });
      }
    });

    final currentTotal = CO2Calculator.calculateTotal(
      miles: _transportMiles,
      vehicleType: _vehicleType,
      dietType: _dietType,
      electricityKwh: _electricityKwh,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quick-Log'),
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
                // Real-time calculation display
                _buildRealTimeBadge(theme, currentTotal),
                const SizedBox(height: 24),

                // Transport Section
                _buildTransportSection(theme),
                const SizedBox(height: 20),

                // Diet Section
                _buildDietSection(theme),
                const SizedBox(height: 20),

                // Energy Section
                _buildEnergySection(theme),
                const SizedBox(height: 32),

                // Submit Button
                Semantics(
                  label: 'Save Log Button',
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _saveLog(todayStr),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Daily Log'),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRealTimeBadge(ThemeData theme, double totalCO2) {
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Text(
              'TODAY\'S FOOTPRINT ESTIMATE',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: theme.textTheme.displayLarge!.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  child: Text(totalCO2.toStringAsFixed(2)),
                ),
                const SizedBox(width: 4),
                Text(
                  'kg CO₂e',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Transportation', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Daily Commute: ${_transportMiles.toStringAsFixed(1)} miles',
              style: theme.textTheme.bodyMedium,
            ),
            Semantics(
              label: 'Commute distance slider',
              child: Slider(
                value: _transportMiles,
                min: 0,
                max: 100,
                divisions: 100,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.glassBorder,
                onChanged: (val) {
                  setState(() {
                    _transportMiles = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Text('Vehicle Type:', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VehicleType.values.map((type) {
                final isSelected = _vehicleType == type;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.3),
                  checkmarkColor: AppColors.primary,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _vehicleType = type;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Dietary Footprint', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text('Select your diet type today:', style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            Column(
              children: DietType.values.map((type) {
                final isSelected = _dietType == type;
                IconData icon;
                String description;
                switch (type) {
                  case DietType.meatHeavy:
                    icon = Icons.kebab_dining_rounded;
                    description = 'Frequent red meat / poultry meals';
                    break;
                  case DietType.average:
                    icon = Icons.dinner_dining_rounded;
                    description = 'Mixed diet with moderate meat & dairy';
                    break;
                  case DietType.vegetarian:
                    icon = Icons.egg_alt_rounded;
                    description = 'No meat; includes dairy & eggs';
                    break;
                  case DietType.vegan:
                    icon = Icons.eco_outlined;
                    description = 'Exclusively plant-based diet';
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _dietType = type;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.glassBorder,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.displayName,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  description,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: AppColors.primary)
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergySection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Home Energy', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Electricity Consumption: ${_electricityKwh.toStringAsFixed(1)} kWh',
              style: theme.textTheme.bodyMedium,
            ),
            Semantics(
              label: 'Energy consumption slider',
              child: Slider(
                value: _electricityKwh,
                min: 0,
                max: 50,
                divisions: 50,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.glassBorder,
                onChanged: (val) {
                  setState(() {
                    _electricityKwh = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: Average household usage is ~30 kWh per day.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLog(String todayStr) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        throw Exception('User must be logged in to save logs.');
      }

      final totalCO2 = CO2Calculator.calculateTotal(
        miles: _transportMiles,
        vehicleType: _vehicleType,
        dietType: _dietType,
        electricityKwh: _electricityKwh,
      );

      final log = DailyLog(
        date: todayStr,
        transportMiles: _transportMiles,
        vehicleType: _vehicleType,
        dietType: _dietType,
        electricityKwh: _electricityKwh,
        totalCO2Kg: totalCO2,
        timestamp: DateTime.now(),
      );

      final logRepo = ref.read(logRepositoryProvider);
      await logRepo.saveDailyLog(user.uid, log);

      // Invalidate providers to force reload
      ref.invalidate(todaysLogProvider);
      ref.invalidate(recentLogsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Daily log saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save log: $e'),
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
}
