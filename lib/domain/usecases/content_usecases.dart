import 'package:simple_quizlet_mobile_app/domain/entities/folder_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/lesson_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/folder_repository.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/lesson_repository.dart';

class GetPublicLessonsUseCase {
  final LessonRepository _repository;
  GetPublicLessonsUseCase(this._repository);

  Future<List<LessonEntity>> call() => _repository.getPublicLessons();
}

class GetOfficialFoldersUseCase {
  final FolderRepository _repository;
  GetOfficialFoldersUseCase(this._repository);

  Future<List<FolderEntity>> call() => _repository.getOfficialFolders();
}

class GetFolderUseCase {
  final FolderRepository _repository;
  GetFolderUseCase(this._repository);

  Future<FolderEntity> call(String folderId) => _repository.getFolder(folderId);
}

class GetLessonsInFolderUseCase {
  final FolderRepository _repository;
  GetLessonsInFolderUseCase(this._repository);

  Future<List<LessonEntity>> call(String folderId) =>
      _repository.getLessonsInFolder(folderId);
}

class GetLessonDetailUseCase {
  final LessonRepository _repository;
  GetLessonDetailUseCase(this._repository);

  Future<LessonEntity> call(String lessonId) => _repository.getLessonDetail(lessonId);
}

class SearchLessonsUseCase {
  final LessonRepository _repository;
  SearchLessonsUseCase(this._repository);

  Future<List<LessonEntity>> call(String term) => _repository.searchLessons(term);
}
