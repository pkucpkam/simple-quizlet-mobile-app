import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:simple_quizlet_mobile_app/app.dart';
import 'package:simple_quizlet_mobile_app/core/di/injector.dart';
import 'package:simple_quizlet_mobile_app/core/firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Dependency Injection
  await initInjector();

  runApp(const MyApp());
}
