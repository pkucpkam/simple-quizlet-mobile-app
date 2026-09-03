import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_quizlet_mobile_app/data/models/folder_model.dart';
import 'package:simple_quizlet_mobile_app/data/models/lesson_model.dart';
import 'package:simple_quizlet_mobile_app/data/models/vocab_item_model.dart';

abstract class LessonRemoteDataSource {
  Future<List<LessonModel>> getPublicLessons();
  Future<LessonModel> getLessonDetail(String lessonId);
  Future<List<LessonModel>> searchLessons(String term);
  Future<List<LessonModel>> getMyLessons(String creator);
}

class LessonRemoteDataSourceImpl implements LessonRemoteDataSource {
  final FirebaseFirestore _db;
  LessonRemoteDataSourceImpl(this._db);

  @override
  Future<List<LessonModel>> getPublicLessons() async {
    final q = await _db
        .collection('lessons')
        .where('isPrivate', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return q.docs.map((doc) => LessonModel.fromFirestore(doc)).toList();
  }

  @override
  Future<LessonModel> getLessonDetail(String lessonId) async {
    final lessonDoc = await _db.collection('lessons').doc(lessonId).get();
    if (!lessonDoc.exists) throw Exception('Không tìm thấy bài học');

    final vocabId = lessonDoc.data()!['vocabId'] as String?;
    List<VocabItemModel> vocabulary = [];
    if (vocabId != null && vocabId.isNotEmpty) {
      final vocabDoc = await _db.collection('vocabularies').doc(vocabId).get();
      if (vocabDoc.exists) {
        final words = (vocabDoc.data()!['words'] as List<dynamic>?) ?? [];
        vocabulary = words
            .map((w) => VocabItemModel.fromMap(w as Map<String, dynamic>))
            .toList();
      }
    }
    return LessonModel.fromFirestore(lessonDoc, vocabulary: vocabulary);
  }

  @override
  Future<List<LessonModel>> searchLessons(String term) async {
    final q = await _db
        .collection('lessons')
        .where('isPrivate', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();
    final lower = term.toLowerCase();
    return q.docs
        .map((doc) => LessonModel.fromFirestore(doc))
        .where((l) =>
            l.title.toLowerCase().contains(lower) ||
            l.description.toLowerCase().contains(lower) ||
            l.creator.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Future<List<LessonModel>> getMyLessons(String creator) async {
    final q = await _db
        .collection('lessons')
        .where('creator', isEqualTo: creator)
        .orderBy('createdAt', descending: true)
        .get();
    return q.docs.map((doc) => LessonModel.fromFirestore(doc)).toList();
  }
}

abstract class FolderRemoteDataSource {
  Future<List<FolderModel>> getOfficialFolders();
  Future<FolderModel> getFolder(String folderId);
  Future<List<LessonModel>> getLessonsInFolder(String folderId);
}

class FolderRemoteDataSourceImpl implements FolderRemoteDataSource {
  final FirebaseFirestore _db;
  FolderRemoteDataSourceImpl(this._db);

  @override
  Future<List<FolderModel>> getOfficialFolders() async {
    final q = await _db
        .collection('folders')
        .where('isOfficial', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    return q.docs.map((doc) => FolderModel.fromFirestore(doc)).toList();
  }

  @override
  Future<FolderModel> getFolder(String folderId) async {
    final doc = await _db.collection('folders').doc(folderId).get();
    if (!doc.exists) throw Exception('Không tìm thấy thư mục');
    return FolderModel.fromFirestore(doc);
  }

  @override
  Future<List<LessonModel>> getLessonsInFolder(String folderId) async {
    final q = await _db
        .collection('lessons')
        .where('folderId', isEqualTo: folderId)
        .orderBy('createdAt', descending: true)
        .get();
    return q.docs.map((doc) => LessonModel.fromFirestore(doc)).toList();
  }
}
