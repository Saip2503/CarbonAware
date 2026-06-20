import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logging/providers/log_providers.dart';
import '../data/insights_engine.dart';
import '../models/insight.dart';

final insightsProvider = Provider<List<Insight>>((ref) {
  final logsAsync = ref.watch(recentLogsStreamProvider);
  return logsAsync.when(
    data: (logs) => InsightsEngine.generateInsights(logs),
    loading: () => [],
    error: (_, __) => [],
  );
});
