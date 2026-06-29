import 'package:simple_quizlet_mobile_app/data/datasources/content_remote_datasource.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/folder_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/lesson_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/folder_repository.dart';

class FolderRepositoryImpl implements FolderRepository {
  final FolderRemoteDataSource _dataSource;
  FolderRepositoryImpl(this._dataSource);

  @override
  Future<List<FolderEntity>> getOfficialFolders() => _dataSource.getOfficialFolders();

  @override
  Future<FolderEntity> getFolder(String folderId) => _dataSource.getFolder(folderId);

  @override
  Future<List<LessonEntity>> getLessonsInFolder(String folderId) =>
      _dataSource.getLessonsInFolder(folderId);
}
