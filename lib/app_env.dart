import 'package:firebase_core/firebase_core.dart';
import 'package:haus_des_control/core/console.dart';
import 'core/enums.dart';
import 'firebase_options_dev.dart' as dev_firebase;
import 'firebase_options_prod.dart' as prod_firebase;

class AppEnvironment {
  static const Environment _environment = Environment.dev;

  AppEnvironment._();
  static String get current => _environment.value;

  static bool get isDev => _environment == Environment.dev;
  static bool get isProd => _environment == Environment.prod;

  static FirebaseOptions get firebaseOptions {
    switch (_environment) {
      case Environment.prod:
        return prod_firebase.DefaultFirebaseOptions.currentPlatform;
      case Environment.dev:
        return dev_firebase.DefaultFirebaseOptions.currentPlatform;
    }
  }

  static String get appName {
    switch (_environment) {
      case Environment.prod:
        return 'Haus des Döners';
      case Environment.dev:
        return 'Haus des Döners Dev';
    }
  }

  static void printEnvironment() {
    console('🚀 Running in: ${current.toUpperCase()}', type: DebugType.alert);
  }
}
