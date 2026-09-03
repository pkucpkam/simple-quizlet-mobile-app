import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Services
import 'package:simple_quizlet_mobile_app/core/services/notification_service.dart';
import 'package:simple_quizlet_mobile_app/core/services/notification_scheduler.dart';

// Datasources
import 'package:simple_quizlet_mobile_app/data/datasources/auth_remote_datasource.dart';
import 'package:simple_quizlet_mobile_app/data/datasources/content_remote_datasource.dart';
import 'package:simple_quizlet_mobile_app/data/datasources/history_remote_datasource.dart';
import 'package:simple_quizlet_mobile_app/data/datasources/srs_remote_datasource.dart';

// Repositories
import 'package:simple_quizlet_mobile_app/data/repositories/auth_repository_impl.dart';
import 'package:simple_quizlet_mobile_app/data/repositories/folder_repository_impl.dart';
import 'package:simple_quizlet_mobile_app/data/repositories/history_repository_impl.dart';
import 'package:simple_quizlet_mobile_app/data/repositories/lesson_repository_impl.dart';
import 'package:simple_quizlet_mobile_app/data/repositories/srs_repository_impl.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/auth_repository.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/folder_repository.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/history_repository.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/lesson_repository.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/srs_repository.dart';

// Use Cases
import 'package:simple_quizlet_mobile_app/domain/usecases/auth_usecases.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/content_usecases.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/history_usecases.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/srs_usecases.dart';

// Blocs
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/folder/folder_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/home/home_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/lesson/lesson_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/my_lessons/my_lessons_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/profile/profile_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/srs/srs_bloc.dart';

final GetIt injector = GetIt.instance;

Future<void> initInjector() async {
  // Core / External
  final sharedPreferences = await SharedPreferences.getInstance();
  injector.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  injector.registerLazySingleton<Logger>(() => Logger());
  injector.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  injector.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Notification
  injector.registerLazySingleton<NotificationScheduler>(
    () => NotificationScheduler(
      prefs: injector(),
      notifService: NotificationService.instance,
    ),
  );

  // Data Sources
  injector.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(injector(), injector()),
  );
  injector.registerLazySingleton<LessonRemoteDataSource>(
    () => LessonRemoteDataSourceImpl(injector()),
  );
  injector.registerLazySingleton<FolderRemoteDataSource>(
    () => FolderRemoteDataSourceImpl(injector()),
  );
  injector.registerLazySingleton<HistoryRemoteDataSource>(
    () => HistoryRemoteDataSourceImpl(injector()),
  );
  injector.registerLazySingleton<SrsRemoteDataSource>(
    () => SrsRemoteDataSourceImpl(injector()),
  );

  // Repositories
  injector.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(injector()),
  );
  injector.registerLazySingleton<LessonRepository>(
    () => LessonRepositoryImpl(injector()),
  );
  injector.registerLazySingleton<FolderRepository>(
    () => FolderRepositoryImpl(injector()),
  );
  injector.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(injector()),
  );
  injector.registerLazySingleton<SrsRepository>(
    () => SrsRepositoryImpl(injector()),
  );

  // Use Cases
  injector.registerLazySingleton(() => LoginUseCase(injector()));
  injector.registerLazySingleton(() => RegisterUseCase(injector()));
  injector.registerLazySingleton(() => LogoutUseCase(injector()));
  injector.registerLazySingleton(() => GetCurrentUserUseCase(injector()));

  injector.registerLazySingleton(() => GetPublicLessonsUseCase(injector()));
  injector.registerLazySingleton(() => GetOfficialFoldersUseCase(injector()));
  injector.registerLazySingleton(() => GetFolderUseCase(injector()));
  injector.registerLazySingleton(() => GetLessonsInFolderUseCase(injector()));
  injector.registerLazySingleton(() => GetLessonDetailUseCase(injector()));
  injector.registerLazySingleton(() => SearchLessonsUseCase(injector()));
  injector.registerLazySingleton(() => GetMyLessonsUseCase(injector()));

  injector.registerLazySingleton(() => IncrementStudyStatsUseCase(injector()));
  injector.registerLazySingleton(() => GetStudyStatsUseCase(injector()));
  injector.registerLazySingleton(() => GetDailyActivityUseCase(injector()));

  injector.registerLazySingleton(() => GetDueCardsUseCase(injector()));
  injector.registerLazySingleton(() => GetCardsForLessonUseCase(injector()));
  injector.registerLazySingleton(() => InitializeCardsUseCase(injector()));
  injector.registerLazySingleton(() => ReviewCardUseCase(injector()));
  injector.registerLazySingleton(() => StartReviewSessionUseCase(injector()));
  injector.registerLazySingleton(() => EndReviewSessionUseCase(injector()));

  // Blocs
  injector.registerFactory(
    () => AuthBloc(
      loginUseCase: injector(),
      registerUseCase: injector(),
      logoutUseCase: injector(),
      getCurrentUserUseCase: injector(),
    ),
  );
  injector.registerFactory(
    () => HomeBloc(
      getLessons: injector(),
      getFolders: injector(),
      searchLessons: injector(),
    ),
  );
  injector.registerFactory(
    () => FolderBloc(
      getFolder: injector(),
      getLessonsInFolder: injector(),
    ),
  );
  injector.registerFactory(
    () => LessonBloc(
      getLessonDetail: injector(),
    ),
  );
  injector.registerFactory(
    () => ProfileBloc(
      getStudyStats: injector(),
      getDailyActivity: injector(),
    ),
  );
  injector.registerFactory(
    () => MyLessonsBloc(
      getMyLessons: injector(),
    ),
  );
  injector.registerFactory(
    () => SrsBloc(
      getDueCards: injector(),
      getCardsForLesson: injector(),
      reviewCard: injector(),
      startSession: injector(),
      endSession: injector(),
      incrementStats: injector(),
    ),
  );
}

