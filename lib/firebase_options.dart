import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
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
        return macos;
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
    apiKey: "AIzaSyA6MXi4QCnAKxUeMzlsbH4IYpwmrB9Eat8",
    appId: "1:1047759353392:web:YOUR_WEB_APP_ID", // Reemplaza con tu App ID de web si la tienes
    messagingSenderId: "1047759353392",
    projectId: "abarrotescrud",
    authDomain: "abarrotescrud.firebaseapp.com",
    storageBucket: "abarrotescrud.appspot.com",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyA6MXi4QCnAKxUeMzlsbH4IYpwmrB9Eat8",
    appId: "1:1047759353392:android:a3094f9e2e6857813c9ff5",
    messagingSenderId: "1047759353392",
    projectId: "abarrotescrud",
    storageBucket: "abarrotescrud.appspot.com",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyA6MXi4QCnAKxUeMzlsbH4IYpwmrB9Eat8",
    appId: "1:1047759353392:ios:YOUR_IOS_APP_ID", // Reemplaza si tienes app de iOS
    messagingSenderId: "1047759353392",
    projectId: "abarrotescrud",
    storageBucket: "abarrotescrud.appspot.com",
    iosClientId: "YOUR_IOS_CLIENT_ID",
    iosBundleId: "YOUR_IOS_BUNDLE_ID",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyA6MXi4QCnAKxUeMzlsbH4IYpwmrB9Eat8",
    appId: "1:1047759353392:macos:YOUR_MACOS_APP_ID", // Reemplaza si tienes app de macOS
    messagingSenderId: "1047759353392",
    projectId: "abarrotescrud",
    storageBucket: "abarrotescrud.appspot.com",
    iosClientId: "YOUR_IOS_CLIENT_ID",
    iosBundleId: "YOUR_IOS_BUNDLE_ID",
  );
}
