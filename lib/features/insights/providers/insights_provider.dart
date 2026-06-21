import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logging/providers/log_providers.dart';
import '../data/ai_service.dart';
import '../models/insight.dart';

final aiInsightProvider = FutureProvider<Insight>((ref) async {
  final logsAsync = ref.watch(recentLogsStreamProvider);
  
  // Wait for the stream to provide data
  final logs = logsAsync.value ?? [];
  
  // Fetch AI insight based on logs
  return await AiService.generateAiInsight(logs);
});
