import 'package:firebase_core/firebase_core.dart';
import 'package:haus_des_control/core/console.dart';
import 'firebase_options_dev.dart' as dev_firebase;
import 'firebase_options_prod.dart' as prod_firebase;

class AppEnvironment {
  // Read from command line
  static const String _env = String.fromEnvironment(
    'environment',
    defaultValue: 'dev',
  );

  // Environment types
  static const String dev = 'dev';
  static const String prod = 'prod';

  // Current environment
  static String get current => _env;

  // Easy boolean checks
  static bool get isDev => _env == dev;
  static bool get isProd => _env == prod;

  // Get Firebase options based on environment
  static FirebaseOptions get firebaseOptions {
    return isProd
        ? prod_firebase.DefaultFirebaseOptions.currentPlatform
        : dev_firebase.DefaultFirebaseOptions.currentPlatform;
  }

  // Optional: Get app name
  static String get appName =>
      isProd ? 'Haus des Döners' : 'Haus des Döners Dev';

  // Optional: Print current environment
  static void printEnvironment() {
    console(
      'App is Running in: ${current.toUpperCase()}',
      type: DebugType.alert,
    );
  }
}
