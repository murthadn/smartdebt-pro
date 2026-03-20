import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZaaiNmZGSdyNK5aGxA_uqm7AetGC1MNY',
    appId: '1:230437300622:android:898e05bc7289540f615cdf',
    messagingSenderId: '230437300622',
    projectId: 'smartdebt-pro',
    storageBucket: 'smartdebt-pro.firebasestorage.app',
  );
}
