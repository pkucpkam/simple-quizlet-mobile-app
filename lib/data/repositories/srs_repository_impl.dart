import 'package:simple_quizlet_mobile_app/data/datasources/srs_remote_datasource.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/srs_card_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/vocab_item_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/srs_repository.dart';

class SrsRepositoryImpl implements SrsRepository {
  final SrsRemoteDataSource _remoteDataSource;
  SrsRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<SrsCardEntity>> getDueCardsForUser(String userId) {
    return _remoteDataSource.getDueCardsForUser(userId);
  }

  @override
  Future<List<SrsCardEntity>> getCardsForLesson(String lessonId, String userId) {
    return _remoteDataSource.getCardsForLesson(lessonId, userId);
  }

  @override
  Future<void> initializeCardsForLesson(
    String lessonId,
    String userId,
    List<VocabItemEntity> vocabulary,
  ) {
    return _remoteDataSource.initializeCardsForLesson(lessonId, userId, vocabulary);
  }

  @override
  Future<SrsCardEntity> reviewCard(String cardId, ReviewRating rating) {
    return _remoteDataSource.reviewCard(cardId, rating);
  }

  @override
  Future<String> startReviewSession(String userId, {String? lessonId}) {
    return _remoteDataSource.startReviewSession(userId, lessonId: lessonId);
  }

  @override
  Future<void> endReviewSession(String sessionId, Map<String, dynamic> stats) {
    return _remoteDataSource.endReviewSession(sessionId, stats);
  }
}
