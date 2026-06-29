import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_quizlet_mobile_app/data/models/vocab_item_model.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/lesson_entity.dart';

class LessonModel extends LessonEntity {
  const LessonModel({
    required super.id,
    required super.title,
    required super.creator,
    required super.vocabId,
    required super.description,
    required super.wordCount,
    required super.isPrivate,
    required super.isOfficial,
    super.folderId,
    required super.createdAt,
    super.vocabulary,
  });

  factory LessonModel.fromFirestore(DocumentSnapshot doc, {List<VocabItemModel>? vocabulary}) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonModel(
      id: doc.id,
      title: data['title'] ?? '',
      creator: data['creator'] ?? '',
      vocabId: data['vocabId'] ?? '',
      description: data['description'] ?? '',
      wordCount: data['wordCount'] ?? 0,
      isPrivate: data['isPrivate'] ?? false,
      isOfficial: data['isOfficial'] ?? false,
      folderId: data['folderId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      vocabulary: vocabulary,
    );
  }
}
