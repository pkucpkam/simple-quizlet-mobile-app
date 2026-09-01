import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_quizlet_mobile_app/data/models/srs_card_model.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/srs_card_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/vocab_item_entity.dart';

abstract class SrsRemoteDataSource {
  Future<List<SrsCardModel>> getDueCardsForUser(String userId);
  Future<List<SrsCardModel>> getCardsForLesson(String lessonId, String userId);
  Future<void> initializeCardsForLesson(
    String lessonId,
    String userId,
    List<VocabItemEntity> vocabulary,
  );
  Future<SrsCardModel> reviewCard(String cardId, ReviewRating rating);
  Future<String> startReviewSession(String userId, {String? lessonId});
  Future<void> endReviewSession(String sessionId, Map<String, dynamic> stats);
}

class SrsRemoteDataSourceImpl implements SrsRemoteDataSource {
  final FirebaseFirestore _db;
  SrsRemoteDataSourceImpl(this._db);

  @override
  Future<List<SrsCardModel>> getDueCardsForUser(String userId) async {
    final query = await _db
        .collection('srsCards')
        .where('userId', isEqualTo: userId)
        .orderBy('nextReview', descending: false)
        .get();

    final now = DateTime.now();
    return query.docs
        .map((doc) => SrsCardModel.fromFirestore(doc))
        .where((card) => card.nextReview.isBefore(now) || card.nextReview.isAtSameMomentAs(now))
        .toList();
  }

  @override
  Future<List<SrsCardModel>> getCardsForLesson(String lessonId, String userId) async {
    final query = await _db
        .collection('srsCards')
        .where('lessonId', isEqualTo: lessonId)
        .where('userId', isEqualTo: userId)
        .get();

    return query.docs.map((doc) => SrsCardModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> initializeCardsForLesson(
    String lessonId,
    String userId,
    List<VocabItemEntity> vocabulary,
  ) async {
    final existing = await getCardsForLesson(lessonId, userId);
    if (existing.isNotEmpty) return; // Already initialized

    final batch = _db.batch();
    final now = DateTime.now();

    for (final item in vocabulary) {
      final docRef = _db.collection('srsCards').doc();
      final card = SrsCardModel(
        id: docRef.id,
        wordId: '${lessonId}_${item.word}',
        word: item.word,
        definition: item.definition,
        easeFactor: 2.5,
        interval: 1,
        repetitions: 0,
        nextReview: now,
        totalReviews: 0,
        correctCount: 0,
        incorrectCount: 0,
        streak: 0,
        lessonId: lessonId,
        userId: userId,
        createdAt: now,
        updatedAt: now,
      );
      batch.set(docRef, card.toFirestore());
    }

    await batch.commit();
  }

  @override
  Future<SrsCardModel> reviewCard(String cardId, ReviewRating rating) async {
    final docRef = _db.collection('srsCards').doc(cardId);
    final doc = await docRef.get();
    if (!doc.exists) throw Exception('Thẻ SRS không tồn tại');

    final card = SrsCardModel.fromFirestore(doc);

    // SM-2 Algorithm calculation
    final quality = switch (rating) {
      ReviewRating.again => 0,
      ReviewRating.hard => 3,
      ReviewRating.good => 4,
      ReviewRating.easy => 5,
    };

    double newEF = card.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEF < 1.3) newEF = 1.3;
    if (newEF > 2.8) newEF = 2.8;

    int newInterval;
    int newReps;
    final isCorrect = rating != ReviewRating.again;

    if (rating == ReviewRating.again) {
      newInterval = 1;
      newReps = 0;
    } else {
      if (card.repetitions == 0) {
        newInterval = 1;
      } else if (card.repetitions == 1) {
        newInterval = 6;
      } else {
        newInterval = (card.interval * newEF).round();
      }
      newReps = card.repetitions + 1;
    }

    final now = DateTime.now();
    final nextReview = now.add(Duration(days: newInterval));
    final newStreak = isCorrect ? card.streak + 1 : 0;

    final updatedData = {
      'easeFactor': newEF,
      'interval': newInterval,
      'repetitions': newReps,
      'nextReview': Timestamp.fromDate(nextReview),
      'lastReview': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'totalReviews': FieldValue.increment(1),
      'correctCount': FieldValue.increment(isCorrect ? 1 : 0),
      'incorrectCount': FieldValue.increment(isCorrect ? 0 : 1),
      'streak': newStreak,
    };

    await docRef.update(updatedData);

    final updatedDoc = await docRef.get();
    return SrsCardModel.fromFirestore(updatedDoc);
  }

  @override
  Future<String> startReviewSession(String userId, {String? lessonId}) async {
    final docRef = await _db.collection('reviewSessions').add({
      'userId': userId,
      if (lessonId != null) 'lessonId': lessonId,
      'startTime': Timestamp.now(),
      'cardsReviewed': 0,
      'correctCount': 0,
      'incorrectCount': 0,
      'totalTime': 0,
      'averageTime': 0,
    });
    return docRef.id;
  }

  @override
  Future<void> endReviewSession(String sessionId, Map<String, dynamic> stats) async {
    final cardsReviewed = (stats['cardsReviewed'] as num?)?.toInt() ?? 0;
    final totalTime = (stats['totalTime'] as num?)?.toDouble() ?? 0.0;
    final avgTime = cardsReviewed > 0 ? totalTime / cardsReviewed : 0.0;

    await _db.collection('reviewSessions').doc(sessionId).update({
      'endTime': Timestamp.now(),
      'cardsReviewed': cardsReviewed,
      'correctCount': stats['correctCount'] ?? 0,
      'incorrectCount': stats['incorrectCount'] ?? 0,
      'totalTime': totalTime,
      'averageTime': avgTime,
    });
  }
}
