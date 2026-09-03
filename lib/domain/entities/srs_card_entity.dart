enum ReviewRating { again, hard, good, easy }

class SrsCardEntity {
  final String? id;
  final String wordId; // "{lessonId}_{word}"
  final String word;
  final String definition;
  final double easeFactor; // 1.3 - 2.8
  final int interval; // in days
  final int repetitions;
  final DateTime nextReview;
  final DateTime? lastReview;
  final int totalReviews;
  final int correctCount;
  final int incorrectCount;
  final int streak;
  final String lessonId;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SrsCardEntity({
    this.id,
    required this.wordId,
    required this.word,
    required this.definition,
    this.easeFactor = 2.5,
    this.interval = 1,
    this.repetitions = 0,
    required this.nextReview,
    this.lastReview,
    this.totalReviews = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.streak = 0,
    required this.lessonId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });
}
