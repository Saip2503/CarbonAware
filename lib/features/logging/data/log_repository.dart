import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_log.dart';

class LogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save/Update daily log
  Future<void> saveDailyLog(String uid, DailyLog log) async {
    if (uid.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(log.date)
        .set(log.toMap());
  }

  // Get daily log for a specific date
  Future<DailyLog?> getDailyLog(String uid, String date) async {
    if (uid.isEmpty) return null;
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(date)
        .get();
        
    if (!doc.exists || doc.data() == null) return null;
    return DailyLog.fromMap(doc.data()!, doc.id);
  }

  // Stream of recent logs (ordered by date descending or ascending)
  Stream<List<DailyLog>> getRecentLogsStream(String uid, {int days = 7}) {
    if (uid.isEmpty) return Stream.value([]);
    
    // We calculate a threshold date to limit our query if needed, or query and take the top N.
    // Querying with order by is best.
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .orderBy('timestamp', descending: true)
        .limit(days)
        .snapshots()
        .map((snapshot) {
          final logs = snapshot.docs.map((doc) {
            return DailyLog.fromMap(doc.data(), doc.id);
          }).toList();
          
          // Return them in chronological order (ascending) for charts
          return logs.reversed.toList();
        });
  }

  // Delete daily log
  Future<void> deleteDailyLog(String uid, String date) async {
    if (uid.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(date)
        .delete();
  }
}
