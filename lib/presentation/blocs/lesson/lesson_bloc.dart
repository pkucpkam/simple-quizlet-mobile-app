import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/lesson_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/content_usecases.dart';

// Events
abstract class LessonEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LessonLoadRequested extends LessonEvent {
  final String lessonId;
  LessonLoadRequested(this.lessonId);
  @override List<Object?> get props => [lessonId];
}

// States
abstract class LessonState extends Equatable {
  @override List<Object?> get props => [];
}
class LessonInitial extends LessonState {}
class LessonLoading extends LessonState {}
class LessonLoaded extends LessonState {
  final LessonEntity lesson;
  LessonLoaded(this.lesson);
  @override List<Object?> get props => [lesson];
}
class LessonError extends LessonState {
  final String message;
  LessonError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class LessonBloc extends Bloc<LessonEvent, LessonState> {
  final GetLessonDetailUseCase _getLessonDetail;

  LessonBloc({required GetLessonDetailUseCase getLessonDetail})
      : _getLessonDetail = getLessonDetail,
        super(LessonInitial()) {
    on<LessonLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(LessonLoadRequested event, Emitter<LessonState> emit) async {
    emit(LessonLoading());
    try {
      final lesson = await _getLessonDetail.call(event.lessonId);
      emit(LessonLoaded(lesson));
    } catch (e) {
      emit(LessonError(e.toString()));
    }
  }
}
