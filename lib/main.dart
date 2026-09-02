import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:simple_quizlet_mobile_app/app.dart';
import 'package:simple_quizlet_mobile_app/core/di/injector.dart';
import 'package:simple_quizlet_mobile_app/core/firebase/firebase_options.dart';
import 'package:simple_quizlet_mobile_app/core/services/notification_scheduler.dart';
import 'package:simple_quizlet_mobile_app/core/services/notification_service.dart';

final _log = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Dependency Injection
  await initInjector();

  // Initialize notification plugin (channels only, no scheduling yet)
  try {
    await NotificationService.instance.init();
  } catch (e) {
    _log.w('NotificationService init failed: $e');
  }

  runApp(const MyApp());

  // Request permission + apply schedules AFTER the UI is ready.
  // On Android 12+ (real devices), permission dialogs need an active
  // Activity window. Running this before runApp causes a silent crash.
  Future.delayed(const Duration(seconds: 1), () async {
    try {
      await NotificationService.instance.requestPermission();
      await injector<NotificationScheduler>().applyAllSettings();
    } catch (e) {
      // SCHEDULE_EXACT_ALARM may be denied on Samsung devices.
      // The app remains fully functional; only scheduled notifications
      // are affected.
      _log.w('Notification scheduling failed (permission denied?): $e');
    }
  });
}

