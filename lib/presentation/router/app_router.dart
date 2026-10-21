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
import 'package:simple_quizlet_mobile_app/presentation/pages/match_rush_page.dart';

import 'dart:async';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(injector<AuthRepository>().authStateChanges),
  redirect: (BuildContext context, GoRouterState state) {
    final authRepo = injector<AuthRepository>();
    final isLoggedIn = authRepo.isAuthenticated;
    final isAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (!isLoggedIn) {
      return isAuthRoute ? null : '/login';
    }

    if (isAuthRoute) {
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
    GoRoute(
      path: '/match',
      builder: (context, state) => const MatchRushPage(),
    ),
    GoRoute(
      path: '/match/:id',
      builder: (context, state) => MatchRushPage(
        lessonId: state.pathParameters['id'],
      ),
    ),
  ],
);
