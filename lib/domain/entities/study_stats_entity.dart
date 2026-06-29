import 'package:equatable/equatable.dart';

class ModeStatsEntity extends Equatable {
  final int sessions;
  final int totalTime; // in seconds
  final DateTime? lastStudied;

  const ModeStatsEntity({
    required this.sessions,
    required this.totalTime,
    this.lastStudied,
  });

  @override
  List<Object?> get props => [sessions, totalTime, lastStudied];
}

class StudyStatsEntity extends Equatable {
  final ModeStatsEntity flashcard;
  final ModeStatsEntity review;
  final ModeStatsEntity test;
  final int totalTime;
  final int totalSessions;
  final DateTime? updatedAt;

  const StudyStatsEntity({
    required this.flashcard,
    required this.review,
    required this.test,
    required this.totalTime,
    required this.totalSessions,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [flashcard, review, test, totalTime, totalSessions, updatedAt];
}
