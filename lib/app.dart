import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_quizlet_mobile_app/core/di/injector.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/folder/folder_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/home/home_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/lesson/lesson_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/profile/profile_bloc.dart';
import 'package:simple_quizlet_mobile_app/presentation/router/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => injector<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => injector<HomeBloc>(),
        ),
        BlocProvider<FolderBloc>(
          create: (context) => injector<FolderBloc>(),
        ),
        BlocProvider<LessonBloc>(
          create: (context) => injector<LessonBloc>(),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => injector<ProfileBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Simple Quizlet',
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
