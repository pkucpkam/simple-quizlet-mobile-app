import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/lesson_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/content_usecases.dart';

// Events
abstract class MyLessonsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MyLessonsLoadRequested extends MyLessonsEvent {
  final String username;
  MyLessonsLoadRequested(this.username);

  @override
  List<Object?> get props => [username];
}

// States
abstract class MyLessonsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MyLessonsInitial extends MyLessonsState {}

class MyLessonsLoading extends MyLessonsState {}

class MyLessonsLoaded extends MyLessonsState {
  final List<LessonEntity> lessons;
  MyLessonsLoaded(this.lessons);

  @override
  List<Object?> get props => [lessons];
}

class MyLessonsError extends MyLessonsState {
  final String message;
  MyLessonsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class MyLessonsBloc extends Bloc<MyLessonsEvent, MyLessonsState> {
  final GetMyLessonsUseCase _getMyLessons;

  MyLessonsBloc({required GetMyLessonsUseCase getMyLessons})
      : _getMyLessons = getMyLessons,
        super(MyLessonsInitial()) {
    on<MyLessonsLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    MyLessonsLoadRequested event,
    Emitter<MyLessonsState> emit,
  ) async {
    emit(MyLessonsLoading());
    try {
      final lessons = await _getMyLessons.call(event.username);
      emit(MyLessonsLoaded(lessons));
    } catch (e) {
      emit(MyLessonsError(e.toString()));
    }
  }
}
