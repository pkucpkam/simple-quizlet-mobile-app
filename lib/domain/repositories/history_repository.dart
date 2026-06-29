import 'package:simple_quizlet_mobile_app/domain/entities/study_stats_entity.dart';

enum StudyMode { flashcard, review, test }

abstract class HistoryRepository {
  Future<void> incrementStudyStats(String userId, StudyMode mode, int timeSpent);
  Future<StudyStatsEntity?> getStudyStats(String userId);
  Future<Map<String, int>> getDailyActivity(String userId);
}
