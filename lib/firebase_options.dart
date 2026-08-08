// File location: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUUiXYiPevzQyg_wLuhwzCk-N9UEx8GFs', //[span_0](start_span)[span_0](end_span)
    appId: '1:719463503810:android:61d5b369a2c3447c00a85b', //[span_1](start_span)[span_1](end_span)
    messagingSenderId: '719463503810', //[span_2](start_span)[span_2](end_span)
    projectId: 'dojo-platform-a5dc8', //[span_3](start_span)[span_3](end_span)
    storageBucket: 'dojo-platform-a5dc8.firebasestorage.app', //[span_4](start_span)[span_4](end_span)
  );
}
