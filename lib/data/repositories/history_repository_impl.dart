import 'package:simple_quizlet_mobile_app/data/datasources/history_remote_datasource.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/study_stats_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource _dataSource;
  HistoryRepositoryImpl(this._dataSource);

  @override
  Future<void> incrementStudyStats(String userId, StudyMode mode, int timeSpent) =>
      _dataSource.incrementStudyStats(userId, mode, timeSpent);

  @override
  Future<StudyStatsEntity?> getStudyStats(String userId) =>
      _dataSource.getStudyStats(userId);

  @override
  Future<Map<String, int>> getDailyActivity(String userId) =>
      _dataSource.getDailyActivity(userId);
}
