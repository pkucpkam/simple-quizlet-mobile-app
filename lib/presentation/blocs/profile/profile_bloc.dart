import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/study_stats_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/history_usecases.dart';

// Events
abstract class ProfileEvent extends Equatable {
  @override List<Object?> get props => [];
}
class ProfileLoadRequested extends ProfileEvent {
  final String userId;
  ProfileLoadRequested(this.userId);
  @override List<Object?> get props => [userId];
}

// States
abstract class ProfileState extends Equatable {
  @override List<Object?> get props => [];
}
class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}
class ProfileLoaded extends ProfileState {
  final StudyStatsEntity? stats;
  final Map<String, int> dailyActivity;
  ProfileLoaded({this.stats, required this.dailyActivity});
  @override List<Object?> get props => [stats, dailyActivity];
}
class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetStudyStatsUseCase _getStudyStats;
  final GetDailyActivityUseCase _getDailyActivity;

  ProfileBloc({
    required GetStudyStatsUseCase getStudyStats,
    required GetDailyActivityUseCase getDailyActivity,
  })  : _getStudyStats = getStudyStats,
        _getDailyActivity = getDailyActivity,
        super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final results = await Future.wait([
        _getStudyStats.call(event.userId),
        _getDailyActivity.call(event.userId),
      ]);
      emit(ProfileLoaded(
        stats: results[0] as StudyStatsEntity?,
        dailyActivity: results[1] as Map<String, int>,
      ));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
