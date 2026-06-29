import 'package:simple_quizlet_mobile_app/data/datasources/content_remote_datasource.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/lesson_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/lesson_repository.dart';

class LessonRepositoryImpl implements LessonRepository {
  final LessonRemoteDataSource _dataSource;
  LessonRepositoryImpl(this._dataSource);

  @override
  Future<List<LessonEntity>> getPublicLessons() => _dataSource.getPublicLessons();

  @override
  Future<LessonEntity> getLessonDetail(String lessonId) =>
      _dataSource.getLessonDetail(lessonId);

  @override
  Future<List<LessonEntity>> searchLessons(String term) =>
      _dataSource.searchLessons(term);
}
