import 'package:simple_quizlet_mobile_app/domain/entities/lesson_entity.dart';

abstract class LessonRepository {
  Future<List<LessonEntity>> getPublicLessons();
  Future<LessonEntity> getLessonDetail(String lessonId);
  Future<List<LessonEntity>> searchLessons(String term);
}
