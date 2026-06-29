import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/folder_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/lesson_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/content_usecases.dart';

// Events
abstract class HomeEvent extends Equatable {
  @override List<Object?> get props => [];
}
class HomeLoadRequested extends HomeEvent {}
class HomeSearchChanged extends HomeEvent {
  final String term;
  HomeSearchChanged(this.term);
  @override List<Object?> get props => [term];
}
class HomeSearchCleared extends HomeEvent {}

// States
abstract class HomeState extends Equatable {
  @override List<Object?> get props => [];
}
class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final List<FolderEntity> officialFolders;
  final List<LessonEntity> lessons;
  final String searchTerm;
  HomeLoaded({required this.officialFolders, required this.lessons, this.searchTerm = ''});
  @override List<Object?> get props => [officialFolders, lessons, searchTerm];
}
class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetPublicLessonsUseCase _getLessons;
  final GetOfficialFoldersUseCase _getFolders;
  final SearchLessonsUseCase _searchLessons;

  List<LessonEntity> _allLessons = [];
  List<FolderEntity> _allFolders = [];

  HomeBloc({
    required GetPublicLessonsUseCase getLessons,
    required GetOfficialFoldersUseCase getFolders,
    required SearchLessonsUseCase searchLessons,
  })  : _getLessons = getLessons,
        _getFolders = getFolders,
        _searchLessons = searchLessons,
        super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeSearchChanged>(_onSearch);
    on<HomeSearchCleared>(_onSearchCleared);
  }

  Future<void> _onLoad(HomeLoadRequested event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final results = await Future.wait([_getFolders.call(), _getLessons.call()]);
      _allFolders = results[0] as List<FolderEntity>;
      _allLessons = results[1] as List<LessonEntity>;
      emit(HomeLoaded(officialFolders: _allFolders, lessons: _allLessons));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onSearch(HomeSearchChanged event, Emitter<HomeState> emit) async {
    if (event.term.isEmpty) {
      emit(HomeLoaded(officialFolders: _allFolders, lessons: _allLessons));
      return;
    }
    try {
      final results = await _searchLessons.call(event.term);
      emit(HomeLoaded(
        officialFolders: _allFolders,
        lessons: results,
        searchTerm: event.term,
      ));
    } catch (_) {}
  }

  Future<void> _onSearchCleared(HomeSearchCleared event, Emitter<HomeState> emit) async {
    emit(HomeLoaded(officialFolders: _allFolders, lessons: _allLessons));
  }
}
