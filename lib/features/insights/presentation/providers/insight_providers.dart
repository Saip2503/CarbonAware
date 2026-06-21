import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../logging/presentation/providers/log_providers.dart';
import '../../data/insights_engine.dart';
import '../../domain/insight.dart';

final insightsProvider = FutureProvider<List<Insight>>((ref) async {
  final logsAsync = ref.watch(recentLogsStreamProvider);
  if (logsAsync.value == null) {
    return [];
  }
  return await InsightsEngine.generateInsights(logsAsync.value!);
});
