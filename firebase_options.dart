import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platform is not configured for this app.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS platform is not configured for this app.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'macOS platform is not configured for this app.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Windows platform is not configured for this app.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Linux platform is not configured for this app.',
        );
      default:
        throw UnsupportedError(
          'This platform is not supported for this app.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDQDPWozXhd9GXQdbs0C5o14CluV6QJj_U',
    appId: '1:1062237626846:android:5098c01b027634e5c3fd4f',
    messagingSenderId: '1062237626846',
    projectId: 'binger-32229',
    databaseURL: 'https://binger-32229-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'binger-32229.firebasestorage.app',
  );
}