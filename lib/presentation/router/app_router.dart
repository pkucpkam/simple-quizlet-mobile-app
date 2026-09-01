import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_quizlet_mobile_app/core/di/injector.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/auth_repository.dart';
import 'package:simple_quizlet_mobile_app/presentation/pages/folder_page.dart';
import 'package:simple_quizlet_mobile_app/presentation/pages/home_page.dart';
import 'package:simple_quizlet_mobile_app/presentation/pages/lesson_page.dart';
import 'package:simple_quizlet_mobile_app/presentation/pages/login_page.dart';
import 'package:simple_quizlet_mobile_app/presentation/pages/register_page.dart';
import 'package:simple_quizlet_mobile_app/presentation/pages/flashcard_page.dart';
import 'package:simple_quizlet_mobile_app/presentation/pages/review_page.dart';
import 'package:simple_quizlet_mobile_app/presentation/pages/test_page.dart';
import 'package:simple_quizlet_mobile_app/presentation/pages/profile_page.dart';

import 'package:simple_quizlet_mobile_app/presentation/pages/my_lessons_page.dart';
import 'package:simple_quizlet_mobile_app/presentation/pages/srs_review_page.dart';
import 'package:simple_quizlet_mobile_app/presentation/pages/notification_settings_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) async {
    final authRepo = injector<AuthRepository>();
    final user = await authRepo.getCurrentUser();
    final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (user == null) {
      return loggingIn ? null : '/login';
    }

    if (loggingIn) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/my-lessons',
      builder: (context, state) => const MyLessonsPage(),
    ),
    GoRoute(
      path: '/srs-review',
      builder: (context, state) => const SrsReviewPage(),
    ),
    GoRoute(
      path: '/srs-review/:lessonId',
      builder: (context, state) => SrsReviewPage(
        lessonId: state.pathParameters['lessonId'],
      ),
    ),
    GoRoute(
      path: '/folder/:id',
      builder: (context, state) => FolderPage(
        folderId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/lesson/:id',
      builder: (context, state) => LessonPage(
        lessonId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/study/:id',
      builder: (context, state) => FlashcardPage(
        lessonId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/review/:id',
      builder: (context, state) => ReviewPage(
        lessonId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/test/:id',
      builder: (context, state) => TestPage(
        lessonId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/notification-settings',
      builder: (context, state) => const NotificationSettingsPage(),
    ),
  ],
);
