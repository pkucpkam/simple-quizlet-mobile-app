import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/folder_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/entities/lesson_entity.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/content_usecases.dart';

// ── Constants ──────────────────────────────────────────────────────
const int _kPageSize = 10;

// ── Events ─────────────────────────────────────────────────────────
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
class HomeLoadNextPage extends HomeEvent {}
class HomeLoadPrevPage extends HomeEvent {}
class HomeGoToPage extends HomeEvent {
  final int page;
  HomeGoToPage(this.page);
  @override List<Object?> get props => [page];
}

// ── States ─────────────────────────────────────────────────────────
abstract class HomeState extends Equatable {
  @override List<Object?> get props => [];
}
class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final List<FolderEntity> officialFolders;

  // Visible items on current page
  final List<LessonEntity> lessons;

  // Pagination
  final int currentPage;
  final int totalPages;
  final int totalCount;

  // Search
  final String searchTerm;

  HomeLoaded({
    required this.officialFolders,
    required this.lessons,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    this.searchTerm = '',
  });

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPrevPage => currentPage > 1;

  @override
  List<Object?> get props => [officialFolders, lessons, currentPage, totalPages, searchTerm];
}
class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ───────────────────────────────────────────────────────────
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetPublicLessonsUseCase _getLessons;
  final GetOfficialFoldersUseCase _getFolders;
  final SearchLessonsUseCase _searchLessons;

  List<LessonEntity> _allLessons = [];
  List<LessonEntity> _filteredLessons = [];
  List<FolderEntity> _allFolders = [];
  int _currentPage = 1;

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
    on<HomeLoadNextPage>(_onNextPage);
    on<HomeLoadPrevPage>(_onPrevPage);
    on<HomeGoToPage>(_onGoToPage);
  }

  // ── Helpers ──────────────────────────────────────────────────────

  HomeLoaded _buildPageState({String searchTerm = ''}) {
    final total = _filteredLessons.length;
    final totalPages = (total / _kPageSize).ceil().clamp(1, double.maxFinite).toInt();
    // Clamp page in case filter reduced total pages
    _currentPage = _currentPage.clamp(1, totalPages);
    final start = (_currentPage - 1) * _kPageSize;
    final end = (start + _kPageSize).clamp(0, total);
    return HomeLoaded(
      officialFolders: _allFolders,
      lessons: _filteredLessons.sublist(start, end),
      currentPage: _currentPage,
      totalPages: totalPages,
      totalCount: total,
      searchTerm: searchTerm,
    );
  }

  // ── Handlers ─────────────────────────────────────────────────────

  Future<void> _onLoad(HomeLoadRequested event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final results = await Future.wait([_getFolders.call(), _getLessons.call()]);
      _allFolders = results[0] as List<FolderEntity>;
      _allLessons = results[1] as List<LessonEntity>;
      _filteredLessons = _allLessons;
      _currentPage = 1;
      emit(_buildPageState());
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onSearch(HomeSearchChanged event, Emitter<HomeState> emit) async {
    if (event.term.isEmpty) {
      _filteredLessons = _allLessons;
      _currentPage = 1;
      emit(_buildPageState());
      return;
    }
    try {
      final results = await _searchLessons.call(event.term);
      _filteredLessons = results;
      _currentPage = 1;
      emit(_buildPageState(searchTerm: event.term));
    } catch (_) {}
  }

  Future<void> _onSearchCleared(HomeSearchCleared event, Emitter<HomeState> emit) async {
    _filteredLessons = _allLessons;
    _currentPage = 1;
    emit(_buildPageState());
  }

  Future<void> _onNextPage(HomeLoadNextPage event, Emitter<HomeState> emit) async {
    final state = this.state;
    if (state is HomeLoaded && state.hasNextPage) {
      _currentPage++;
      emit(_buildPageState(searchTerm: state.searchTerm));
    }
  }

  Future<void> _onPrevPage(HomeLoadPrevPage event, Emitter<HomeState> emit) async {
    final state = this.state;
    if (state is HomeLoaded && state.hasPrevPage) {
      _currentPage--;
      emit(_buildPageState(searchTerm: state.searchTerm));
    }
  }

  Future<void> _onGoToPage(HomeGoToPage event, Emitter<HomeState> emit) async {
    final state = this.state;
    if (state is HomeLoaded) {
      _currentPage = event.page.clamp(1, state.totalPages);
      emit(_buildPageState(searchTerm: state.searchTerm));
    }
  }
}
