import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:simple_quizlet_mobile_app/app.dart';
import 'package:simple_quizlet_mobile_app/core/di/injector.dart';
import 'package:simple_quizlet_mobile_app/core/firebase/firebase_options.dart';
import 'package:simple_quizlet_mobile_app/domain/repositories/auth_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Simple Quizlet Core User Journey Integration Tests', () {
    testWidgets('Verify app initializes Firebase, Injector, and loads cleanly', (tester) async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await initInjector();

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check whether user is authenticated or login page is displayed
      final authRepo = injector<AuthRepository>();
      if (authRepo.isAuthenticated) {
        expect(find.byType(Scaffold), findsWidgets);
      } else {
        expect(find.text('Đăng nhập để tiếp tục'), findsOneWidget);
      }
    });
  });
}
