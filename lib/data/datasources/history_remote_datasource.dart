import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/study_stats_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/history_repository.dart';

abstract class HistoryRemoteDataSource {
  Future<void> incrementStudyStats(String userId, StudyMode mode, int timeSpent);
  Future<StudyStatsEntity?> getStudyStats(String userId);
  Future<Map<String, int>> getDailyActivity(String userId);
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  final FirebaseFirestore _db;
  HistoryRemoteDataSourceImpl(this._db);

  DocumentReference _statsDoc(String userId) =>
      _db.doc('history/$userId/aggregate/studyStats');

  DocumentReference _dailyDoc(String userId) =>
      _db.doc('history/$userId/aggregate/dailyLog');

  @override
  Future<void> incrementStudyStats(String userId, StudyMode mode, int timeSpent) async {
    try {
      final modeKey = mode.name;
      await _statsDoc(userId).set({
        modeKey: {
          'sessions': FieldValue.increment(1),
          'totalTime': FieldValue.increment(timeSpent),
          'lastStudied': FieldValue.serverTimestamp(),
        },
        'totalSessions': FieldValue.increment(1),
        'totalTime': FieldValue.increment(timeSpent),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update heatmap
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await _dailyDoc(userId)
          .set({dateStr: FieldValue.increment(1)}, SetOptions(merge: true));
    } catch (e) {
      // silently fail - history is not critical
    }
  }

  @override
  Future<StudyStatsEntity?> getStudyStats(String userId) async {
    try {
      final snap = await _statsDoc(userId).get();
      if (!snap.exists) return null;
      final d = snap.data() as Map<String, dynamic>;

      ModeStatsEntity parseMode(dynamic raw) {
        if (raw == null) return const ModeStatsEntity(sessions: 0, totalTime: 0);
        final m = raw as Map<String, dynamic>;
        return ModeStatsEntity(
          sessions: (m['sessions'] as num?)?.toInt() ?? 0,
          totalTime: (m['totalTime'] as num?)?.toInt() ?? 0,
          lastStudied: (m['lastStudied'] as Timestamp?)?.toDate(),
        );
      }

      return StudyStatsEntity(
        flashcard: parseMode(d['flashcard']),
        review: parseMode(d['review']),
        test: parseMode(d['test']),
        totalTime: (d['totalTime'] as num?)?.toInt() ?? 0,
        totalSessions: (d['totalSessions'] as num?)?.toInt() ?? 0,
        updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, int>> getDailyActivity(String userId) async {
    try {
      final snap = await _dailyDoc(userId).get();
      if (!snap.exists) return {};
      final data = snap.data() as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }
}
