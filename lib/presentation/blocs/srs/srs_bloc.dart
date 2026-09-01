import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/srs_card_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/history_repository.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/history_usecases.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/srs_usecases.dart';

// Events
abstract class SrsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SrsLoadRequested extends SrsEvent {
  final String userId;
  final String? lessonId;
  final int? maxCards;

  SrsLoadRequested({required this.userId, this.lessonId, this.maxCards});

  @override
  List<Object?> get props => [userId, lessonId, maxCards];
}

class SrsCardReviewed extends SrsEvent {
  final ReviewRating rating;
  SrsCardReviewed(this.rating);

  @override
  List<Object?> get props => [rating];
}

class SrsFlipCard extends SrsEvent {}

// States
abstract class SrsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SrsInitial extends SrsState {}

class SrsLoading extends SrsState {}

class SrsCatchupRequired extends SrsState {
  final List<SrsCardEntity> dueCards;
  final String userId;

  SrsCatchupRequired({required this.dueCards, required this.userId});

  @override
  List<Object?> get props => [dueCards, userId];
}

class SrsReady extends SrsState {
  final List<SrsCardEntity> queue;
  final String sessionId;
  final int totalInitialCount;
  final int correctCount;
  final int incorrectCount;
  final bool isFlipped;

  SrsReady({
    required this.queue,
    required this.sessionId,
    required this.totalInitialCount,
    required this.correctCount,
    required this.incorrectCount,
    this.isFlipped = false,
  });

  SrsCardEntity get currentCard => queue.first;

  SrsReady copyWith({
    List<SrsCardEntity>? queue,
    String? sessionId,
    int? totalInitialCount,
    int? correctCount,
    int? incorrectCount,
    bool? isFlipped,
  }) {
    return SrsReady(
      queue: queue ?? this.queue,
      sessionId: sessionId ?? this.sessionId,
      totalInitialCount: totalInitialCount ?? this.totalInitialCount,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      isFlipped: isFlipped ?? this.isFlipped,
    );
  }

  @override
  List<Object?> get props => [queue, sessionId, totalInitialCount, correctCount, incorrectCount, isFlipped];
}

class SrsCompleted extends SrsState {
  final int totalCards;
  final int correctCount;
  final int incorrectCount;
  final int totalTimeSeconds;

  SrsCompleted({
    required this.totalCards,
    required this.correctCount,
    required this.incorrectCount,
    required this.totalTimeSeconds,
  });

  @override
  List<Object?> get props => [totalCards, correctCount, incorrectCount, totalTimeSeconds];
}

class SrsError extends SrsState {
  final String message;
  SrsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class SrsBloc extends Bloc<SrsEvent, SrsState> {
  final GetDueCardsUseCase _getDueCards;
  final GetCardsForLessonUseCase _getCardsForLesson;
  final ReviewCardUseCase _reviewCard;
  final StartReviewSessionUseCase _startSession;
  final EndReviewSessionUseCase _endSession;
  final IncrementStudyStatsUseCase _incrementStats;

  DateTime? _sessionStartTime;
  final Set<String> _persistedCardIds = {};

  SrsBloc({
    required GetDueCardsUseCase getDueCards,
    required GetCardsForLessonUseCase getCardsForLesson,
    required ReviewCardUseCase reviewCard,
    required StartReviewSessionUseCase startSession,
    required EndReviewSessionUseCase endSession,
    required IncrementStudyStatsUseCase incrementStats,
  })  : _getDueCards = getDueCards,
        _getCardsForLesson = getCardsForLesson,
        _reviewCard = reviewCard,
        _startSession = startSession,
        _endSession = endSession,
        _incrementStats = incrementStats,
        super(SrsInitial()) {
    on<SrsLoadRequested>(_onLoadRequested);
    on<SrsCardReviewed>(_onCardReviewed);
    on<SrsFlipCard>(_onFlipCard);
  }

  Future<void> _onLoadRequested(SrsLoadRequested event, Emitter<SrsState> emit) async {
    emit(SrsLoading());
    try {
      List<SrsCardEntity> cards;
      if (event.lessonId != null && event.lessonId!.isNotEmpty) {
        cards = await _getCardsForLesson.call(event.lessonId!, event.userId);
      } else {
        cards = await _getDueCards.call(event.userId);
      }

      if (cards.length > 200 && event.maxCards == null) {
        emit(SrsCatchupRequired(dueCards: cards, userId: event.userId));
        return;
      }

      if (event.maxCards != null && cards.length > event.maxCards!) {
        cards = cards.sublist(0, event.maxCards!);
      }

      if (cards.isEmpty) {
        emit(SrsCompleted(totalCards: 0, correctCount: 0, incorrectCount: 0, totalTimeSeconds: 0));
        return;
      }

      _sessionStartTime = DateTime.now();
      _persistedCardIds.clear();
      final sessionId = await _startSession.call(event.userId, lessonId: event.lessonId);

      emit(SrsReady(
        queue: cards,
        sessionId: sessionId,
        totalInitialCount: cards.length,
        correctCount: 0,
        incorrectCount: 0,
        isFlipped: false,
      ));
    } catch (e) {
      emit(SrsError(e.toString()));
    }
  }

  void _onFlipCard(SrsFlipCard event, Emitter<SrsState> emit) {
    if (state is SrsReady) {
      final currentState = state as SrsReady;
      emit(currentState.copyWith(isFlipped: !currentState.isFlipped));
    }
  }

  Future<void> _onCardReviewed(SrsCardReviewed event, Emitter<SrsState> emit) async {
    if (state is! SrsReady) return;
    final currentState = state as SrsReady;
    final card = currentState.currentCard;

    final updatedQueue = List<SrsCardEntity>.from(currentState.queue);
    int newCorrect = currentState.correctCount;
    int newIncorrect = currentState.incorrectCount;

    if (event.rating == ReviewRating.again) {
      newIncorrect++;
      // Push to end of local queue without persisting
      final current = updatedQueue.removeAt(0);
      updatedQueue.add(current);
    } else {
      // Correct (hard/good/easy)
      if (card.id != null && !_persistedCardIds.contains(card.id)) {
        newCorrect++;
        _persistedCardIds.add(card.id!);
        try {
          await _reviewCard.call(card.id!, event.rating);
        } catch (_) {}
      }
      updatedQueue.removeAt(0);
    }

    if (updatedQueue.isEmpty) {
      final totalTime = _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inSeconds
          : 0;

      try {
        await _endSession.call(currentState.sessionId, {
          'cardsReviewed': currentState.totalInitialCount,
          'correctCount': newCorrect,
          'incorrectCount': newIncorrect,
          'totalTime': totalTime,
        });

        final userId = card.userId;
        await _incrementStats.call(userId, StudyMode.review, totalTime);
      } catch (_) {}

      emit(SrsCompleted(
        totalCards: currentState.totalInitialCount,
        correctCount: newCorrect,
        incorrectCount: newIncorrect,
        totalTimeSeconds: totalTime,
      ));
    } else {
      emit(currentState.copyWith(
        queue: updatedQueue,
        correctCount: newCorrect,
        incorrectCount: newIncorrect,
        isFlipped: false,
      ));
    }
  }
}
