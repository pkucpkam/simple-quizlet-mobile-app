import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/folder_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/lesson_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/content_usecases.dart';

// Events
abstract class FolderEvent extends Equatable {
  @override List<Object?> get props => [];
}
class FolderLoadRequested extends FolderEvent {
  final String folderId;
  FolderLoadRequested(this.folderId);
  @override List<Object?> get props => [folderId];
}

// States
abstract class FolderState extends Equatable {
  @override List<Object?> get props => [];
}
class FolderInitial extends FolderState {}
class FolderLoading extends FolderState {}
class FolderLoaded extends FolderState {
  final FolderEntity folder;
  final List<LessonEntity> lessons;
  FolderLoaded({required this.folder, required this.lessons});
  @override List<Object?> get props => [folder, lessons];
}
class FolderError extends FolderState {
  final String message;
  FolderError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class FolderBloc extends Bloc<FolderEvent, FolderState> {
  final GetFolderUseCase _getFolder;
  final GetLessonsInFolderUseCase _getLessonsInFolder;

  FolderBloc({
    required GetFolderUseCase getFolder,
    required GetLessonsInFolderUseCase getLessonsInFolder,
  })  : _getFolder = getFolder,
        _getLessonsInFolder = getLessonsInFolder,
        super(FolderInitial()) {
    on<FolderLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(FolderLoadRequested event, Emitter<FolderState> emit) async {
    emit(FolderLoading());
    try {
      final results = await Future.wait([
        _getFolder.call(event.folderId),
        _getLessonsInFolder.call(event.folderId),
      ]);
      emit(FolderLoaded(
        folder: results[0] as FolderEntity,
        lessons: results[1] as List<LessonEntity>,
      ));
    } catch (e) {
      emit(FolderError(e.toString()));
    }
  }
}
