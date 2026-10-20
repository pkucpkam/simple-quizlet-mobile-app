import 'package:flutter_test/flutter_test.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/srs_card_entity.dart';

// Standalone SM-2 calculation utility matching SrsRemoteDataSource implementation
class Sm2Calculator {
  static ({double newEaseFactor, int newInterval, int newRepetitions, int newStreak}) calculate({
    required double currentEaseFactor,
    required int currentInterval,
    required int currentRepetitions,
    required int currentStreak,
    required ReviewRating rating,
  }) {
    final quality = switch (rating) {
      ReviewRating.again => 0,
      ReviewRating.hard => 3,
      ReviewRating.good => 4,
      ReviewRating.easy => 5,
    };

    double newEF = currentEaseFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEF < 1.3) newEF = 1.3;
    if (newEF > 2.8) newEF = 2.8;

    int newInterval;
    int newReps;
    final isCorrect = rating != ReviewRating.again;

    if (rating == ReviewRating.again) {
      newInterval = 1;
      newReps = 0;
    } else {
      if (currentRepetitions == 0) {
        newInterval = 1;
      } else if (currentRepetitions == 1) {
        newInterval = 6;
      } else {
        newInterval = (currentInterval * newEF).round();
      }
      newReps = currentRepetitions + 1;
    }

    final newStreak = isCorrect ? currentStreak + 1 : 0;

    return (
      newEaseFactor: newEF,
      newInterval: newInterval,
      newRepetitions: newReps,
      newStreak: newStreak,
    );
  }
}

void main() {
  group('SM-2 Spaced Repetition Algorithm Tests', () {
    test('ReviewRating.again resets repetitions, interval, and streak', () {
      final res = Sm2Calculator.calculate(
        currentEaseFactor: 2.5,
        currentInterval: 14,
        currentRepetitions: 4,
        currentStreak: 4,
        rating: ReviewRating.again,
      );

      expect(res.newInterval, 1);
      expect(res.newRepetitions, 0);
      expect(res.newStreak, 0);
      expect(res.newEaseFactor, lessThan(2.5));
      expect(res.newEaseFactor, greaterThanOrEqualTo(1.3));
    });

    test('First review with good sets interval to 1 and increments repetitions', () {
      final res = Sm2Calculator.calculate(
        currentEaseFactor: 2.5,
        currentInterval: 1,
        currentRepetitions: 0,
        currentStreak: 0,
        rating: ReviewRating.good,
      );

      expect(res.newInterval, 1);
      expect(res.newRepetitions, 1);
      expect(res.newStreak, 1);
    });

    test('Second review with good sets interval to 6 days', () {
      final res = Sm2Calculator.calculate(
        currentEaseFactor: 2.5,
        currentInterval: 1,
        currentRepetitions: 1,
        currentStreak: 1,
        rating: ReviewRating.good,
      );

      expect(res.newInterval, 6);
      expect(res.newRepetitions, 2);
      expect(res.newStreak, 2);
    });

    test('Subsequent reviews multiply interval by new easeFactor', () {
      final res = Sm2Calculator.calculate(
        currentEaseFactor: 2.5,
        currentInterval: 6,
        currentRepetitions: 2,
        currentStreak: 2,
        rating: ReviewRating.good,
      );

      expect(res.newRepetitions, 3);
      expect(res.newInterval, (6 * res.newEaseFactor).round());
      expect(res.newInterval, greaterThan(6));
    });

    test('EaseFactor is clamped between 1.3 and 2.8', () {
      // Multiple agains should not drop below 1.3
      var ef = 1.4;
      for (int i = 0; i < 5; i++) {
        final res = Sm2Calculator.calculate(
          currentEaseFactor: ef,
          currentInterval: 1,
          currentRepetitions: 0,
          currentStreak: 0,
          rating: ReviewRating.again,
        );
        ef = res.newEaseFactor;
      }
      expect(ef, 1.3);

      // Multiple easys should not exceed 2.8
      ef = 2.7;
      for (int i = 0; i < 5; i++) {
        final res = Sm2Calculator.calculate(
          currentEaseFactor: ef,
          currentInterval: 1,
          currentRepetitions: 0,
          currentStreak: 0,
          rating: ReviewRating.easy,
        );
        ef = res.newEaseFactor;
      }
      expect(ef, 2.8);
    });
  });
}
