// File generated manually from the Vivot Firebase project settings.
// Keep this separate from the StimmApp production options.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptionsVivotProd {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptionsVivotProd are not configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptionsVivotProd are not configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptionsVivotProd are not configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptionsVivotProd are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCHjltgsBpIcmb_0gE_AEcV0nHJfJjxxOA',
    appId: '1:67384688969:web:91d2ca871b2a3142da5a98',
    messagingSenderId: '67384688969',
    projectId: 'vivot-prod',
    authDomain: 'vivot-prod.firebaseapp.com',
    storageBucket: 'vivot-prod.firebasestorage.app',
    measurementId: 'G-YPC31EQDGD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhAM2kX7m0gmk91ZX4B_96ddQfyGR0-mE',
    appId: '1:67384688969:android:88a1de7997a1e235da5a98',
    messagingSenderId: '67384688969',
    projectId: 'vivot-prod',
    storageBucket: 'vivot-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAy6RMvEMgnDihhKgE0d22ziWIOiQeUeX8',
    appId: '1:67384688969:ios:707183ed07ea36d3da5a98',
    messagingSenderId: '67384688969',
    projectId: 'vivot-prod',
    storageBucket: 'vivot-prod.firebasestorage.app',
    iosBundleId: 'com.trainvent.vivot',
  );
}
