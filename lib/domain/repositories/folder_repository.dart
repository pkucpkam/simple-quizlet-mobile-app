import 'package:simple_quizlet_mobile_app/domain/entities/folder_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/lesson_entity.dart';

abstract class FolderRepository {
  Future<List<FolderEntity>> getOfficialFolders();
  Future<FolderEntity> getFolder(String folderId);
  Future<List<LessonEntity>> getLessonsInFolder(String folderId);
}
