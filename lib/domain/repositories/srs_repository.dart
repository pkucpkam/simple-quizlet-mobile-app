import 'package:simple_quizlet_mobile_app/domain/entities/srs_card_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/vocab_item_entity.dart';

abstract class SrsRepository {
  Future<List<SrsCardEntity>> getDueCardsForUser(String userId);
  Future<List<SrsCardEntity>> getCardsForLesson(String lessonId, String userId);
  Future<void> initializeCardsForLesson(
    String lessonId,
    String userId,
    List<VocabItemEntity> vocabulary,
  );
  Future<SrsCardEntity> reviewCard(String cardId, ReviewRating rating);
  Future<String> startReviewSession(String userId, {String? lessonId});
  Future<void> endReviewSession(String sessionId, Map<String, dynamic> stats);
}
