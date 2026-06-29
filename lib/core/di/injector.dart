import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Datasources
import 'package:simple_quizlet_mobile_app/data/datasources/auth_remote_datasource.dart';
import 'package:simple_quizlet_mobile_app/data/datasources/content_remote_datasource.dart';
import 'package:simple_quizlet_mobile_app/data/datasources/history_remote_datasource.dart';

// Repositories
import 'package:simple_quizlet_mobile_app/data/repositories/auth_repository_impl.dart';
import 'package:simple_quizlet_mobile_app/data/repositories/folder_repository_impl.dart';
import 'package:simple_quizlet_mobile_app/data/repositories/history_repository_impl.dart';
import 'package:simple_quizlet_mobile_app/data/repositories/lesson_repository_impl.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/auth_repository.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/folder_repository.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/history_repository.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/lesson_repository.dart';

// Use Cases
import 'package:simple_quizlet_mobile_app/domain/usecases/auth_usecases.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/content_usecases.dart';
import 'package:simple_quizlet_mobile_app/domain/usecases/history_usecases.dart';

// Blocs
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/folder/folder_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/home/home_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/lesson/lesson_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/profile/profile_bloc.dart';

final GetIt injector = GetIt.instance;

Future<void> initInjector() async {
  // Core / External
  final sharedPreferences = await SharedPreferences.getInstance();
  injector.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  injector.registerLazySingleton<Logger>(() => Logger());
  injector.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  injector.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

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

  injector.registerLazySingleton(() => IncrementStudyStatsUseCase(injector()));
  injector.registerLazySingleton(() => GetStudyStatsUseCase(injector()));
  injector.registerLazySingleton(() => GetDailyActivityUseCase(injector()));

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
}
