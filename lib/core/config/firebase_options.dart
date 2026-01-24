import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_-TkN0pZvPtLX_EJw7j1v3EfL8hQluCk',
    appId: '1:410774179221:web:b7374fe96edb504fde7a9c',
    messagingSenderId: '410774179221',
    projectId: 'ist-flutter-android-app',
    authDomain: 'ist-flutter-android-app.firebaseapp.com',
    storageBucket: 'ist-flutter-android-app.firebasestorage.app',
    measurementId: 'G-BDDL4REB41',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUrRcdchXJsI_R5dw2A6FznmZt7cS7dbw',
    appId: '1:410774179221:android:224e3f153b7c5fe8de7a9c',
    messagingSenderId: '410774179221',
    projectId: 'ist-flutter-android-app',
    storageBucket: 'ist-flutter-android-app.firebasestorage.app',
  );
}
