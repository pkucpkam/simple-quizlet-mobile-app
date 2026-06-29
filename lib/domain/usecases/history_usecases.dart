import 'package:simple_quizlet_mobile_app/domain/entities/study_stats_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/history_repository.dart';

class IncrementStudyStatsUseCase {
  final HistoryRepository _repository;
  IncrementStudyStatsUseCase(this._repository);

  Future<void> call(String userId, StudyMode mode, int timeSpent) =>
      _repository.incrementStudyStats(userId, mode, timeSpent);
}

class GetStudyStatsUseCase {
  final HistoryRepository _repository;
  GetStudyStatsUseCase(this._repository);

  Future<StudyStatsEntity?> call(String userId) => _repository.getStudyStats(userId);
}

class GetDailyActivityUseCase {
  final HistoryRepository _repository;
  GetDailyActivityUseCase(this._repository);

  Future<Map<String, int>> call(String userId) => _repository.getDailyActivity(userId);
}
