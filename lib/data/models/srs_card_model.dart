import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/srs_card_entity.dart';

class SrsCardModel extends SrsCardEntity {
  const SrsCardModel({
    super.id,
    required super.wordId,
    required super.word,
    required super.definition,
    super.easeFactor = 2.5,
    super.interval = 1,
    super.repetitions = 0,
    required super.nextReview,
    super.lastReview,
    super.totalReviews = 0,
    super.correctCount = 0,
    super.incorrectCount = 0,
    super.streak = 0,
    required super.lessonId,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SrsCardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SrsCardModel(
      id: doc.id,
      wordId: data['wordId'] as String? ?? '',
      word: data['word'] as String? ?? '',
      definition: data['definition'] as String? ?? '',
      easeFactor: (data['easeFactor'] as num?)?.toDouble() ?? 2.5,
      interval: (data['interval'] as num?)?.toInt() ?? 1,
      repetitions: (data['repetitions'] as num?)?.toInt() ?? 0,
      nextReview: (data['nextReview'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastReview: (data['lastReview'] as Timestamp?)?.toDate(),
      totalReviews: (data['totalReviews'] as num?)?.toInt() ?? 0,
      correctCount: (data['correctCount'] as num?)?.toInt() ?? 0,
      incorrectCount: (data['incorrectCount'] as num?)?.toInt() ?? 0,
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      lessonId: data['lessonId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'wordId': wordId,
      'word': word,
      'definition': definition,
      'easeFactor': easeFactor,
      'interval': interval,
      'repetitions': repetitions,
      'nextReview': Timestamp.fromDate(nextReview),
      'lastReview': lastReview != null ? Timestamp.fromDate(lastReview!) : null,
      'totalReviews': totalReviews,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'streak': streak,
      'lessonId': lessonId,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
