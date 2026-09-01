import 'package:simple_quizlet_mobile_app/domain/entities/srs_card_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/vocab_item_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/srs_repository.dart';

class GetDueCardsUseCase {
  final SrsRepository _repository;
  GetDueCardsUseCase(this._repository);

  Future<List<SrsCardEntity>> call(String userId) =>
      _repository.getDueCardsForUser(userId);
}

class GetCardsForLessonUseCase {
  final SrsRepository _repository;
  GetCardsForLessonUseCase(this._repository);

  Future<List<SrsCardEntity>> call(String lessonId, String userId) =>
      _repository.getCardsForLesson(lessonId, userId);
}

class InitializeCardsUseCase {
  final SrsRepository _repository;
  InitializeCardsUseCase(this._repository);

  Future<void> call(String lessonId, String userId, List<VocabItemEntity> vocabulary) =>
      _repository.initializeCardsForLesson(lessonId, userId, vocabulary);
}

class ReviewCardUseCase {
  final SrsRepository _repository;
  ReviewCardUseCase(this._repository);

  Future<SrsCardEntity> call(String cardId, ReviewRating rating) =>
      _repository.reviewCard(cardId, rating);
}

class StartReviewSessionUseCase {
  final SrsRepository _repository;
  StartReviewSessionUseCase(this._repository);

  Future<String> call(String userId, {String? lessonId}) =>
      _repository.startReviewSession(userId, lessonId: lessonId);
}

class EndReviewSessionUseCase {
  final SrsRepository _repository;
  EndReviewSessionUseCase(this._repository);

  Future<void> call(String sessionId, Map<String, dynamic> stats) =>
      _repository.endReviewSession(sessionId, stats);
}
