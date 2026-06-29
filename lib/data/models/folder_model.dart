import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/folder_entity.dart';

class FolderModel extends FolderEntity {
  const FolderModel({
    required super.id,
    required super.name,
    required super.description,
    required super.creator,
    required super.color,
    required super.icon,
    required super.lessonCount,
    required super.isOfficial,
    required super.createdAt,
  });

  factory FolderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FolderModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creator: data['creator'] ?? '',
      color: data['color'] ?? '#3B82F6',
      icon: data['icon'] ?? '📁',
      lessonCount: data['lessonCount'] ?? 0,
      isOfficial: data['isOfficial'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
