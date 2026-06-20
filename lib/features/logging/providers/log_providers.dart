import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/log_repository.dart';
import '../models/daily_log.dart';

final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepository();
});

final recentLogsStreamProvider = StreamProvider<List<DailyLog>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) {
    return Stream.value([]);
  }
  
  final logRepo = ref.watch(logRepositoryProvider);
  return logRepo.getRecentLogsStream(authState.uid, days: 7);
});

// A provider for today's log if it exists, so we can pre-populate the log form
final todaysLogProvider = FutureProvider<DailyLog?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return null;

  final logRepo = ref.watch(logRepositoryProvider);
  final todayStr = DateTime.now().toIso8601String().substring(0, 10);
  return await logRepo.getDailyLog(authState.uid, todayStr);
});
