// lib/firebase_options.dart
// Manually created because user already has google-services.json setup.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
            'you can re-run any of the Fluttermeter configure commands to add web support',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
              'you can re-run any of the Fluttermeter configure commands to add ios support',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
              'you can re-run any of the Fluttermeter configure commands to add macos support',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
              'you can re-run any of the Fluttermeter configure commands to add windows support',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
              'you can re-run any of the Fluttermeter configure commands to add linux support',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // --- YE IDS/KEYS AAPKE PROJECT KE HAIN (DO NOT CHANGE) ---
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcsYLBXhWhY4P-lcfRmR4ZgRh_Li1Iyp4', // Find this in Firebase Console -> Project settings -> General
    appId: '1:707987961175:android:389bb234f47578a0f6fa12', // From your image_3.png keys
    messagingSenderId: '707987961175', // Project Number (Sender ID) - Find in Firebase Console -> Project settings -> Cloud Messaging
    projectId: 'job-portal-44eb0', // From your Firebase Console Project Overview
    storageBucket: 'job-portal-44eb0.appspot.com',
  );
}