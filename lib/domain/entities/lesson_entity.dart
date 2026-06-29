import 'package:equatable/equatable.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/vocab_item_entity.dart';

class LessonEntity extends Equatable {
  final String id;
  final String title;
  final String creator;
  final String vocabId;
  final String description;
  final int wordCount;
  final bool isPrivate;
  final bool isOfficial;
  final String? folderId;
  final DateTime createdAt;
  final List<VocabItemEntity>? vocabulary;

  const LessonEntity({
    required this.id,
    required this.title,
    required this.creator,
    required this.vocabId,
    required this.description,
    required this.wordCount,
    required this.isPrivate,
    required this.isOfficial,
    this.folderId,
    required this.createdAt,
    this.vocabulary,
  });

  @override
  List<Object?> get props => [id, title, creator, vocabId, description, wordCount, isPrivate, isOfficial, folderId, createdAt];
}
