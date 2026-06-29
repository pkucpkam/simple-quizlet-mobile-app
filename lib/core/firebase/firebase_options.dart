import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCOkmnXISstclpPx46KRsB5F5cNC5BGN40',
    appId: '1:361929612581:android:a1b2c3d4e5f60001',
    messagingSenderId: '361929612581',
    projectId: 'simple-quizlet',
    storageBucket: 'simple-quizlet.firebasestorage.app',
  );
}
