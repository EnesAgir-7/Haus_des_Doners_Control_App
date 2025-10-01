import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haus_des_control/firebase_options.dart';
import 'package:haus_des_control/providers/provider_auth.dart';
import 'package:haus_des_control/translations/codegen_loader.g.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'layouts/main_layout.dart';
import 'providers/report_photo_provider.dart';
import 'routes/app_routes.dart';
import 'screens/screen_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((v) {
    runApp(
      EasyLocalization(
        path: 'assets/translations',
        assetLoader: CodegenLoader(),
        supportedLocales: [Locale('en'), Locale('de'), Locale('tr')],
        fallbackLocale: Locale('en'),
        saveLocale: true,
        startLocale: Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslationsForEmptyResources: true,
        child: const MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReportPhotoProvider()),
        ChangeNotifierProvider(create: (_) => ProviderAuth()),
      ],
      child: MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        title: 'Haus des Control',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const AuthWrapper(),
        routes: AppRouter.routes,
      ),
    );
  }
}

/// Reactive wrapper that listens to Firebase auth changes
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderAuth>(
      builder: (context, providerAuth, _) {
        if (providerAuth.currentUser != null) {
          return const MainLayout();
        } else {
          return ScreenAuth();
        }
      },
    );
  }
}
