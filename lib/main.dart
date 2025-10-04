import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haus_des_control/admin/layouts/admin_bottom_nav_bar.dart';
import 'package:haus_des_control/firebase_options.dart';
import 'package:haus_des_control/providers/provider_auth.dart';
import 'package:haus_des_control/providers/provider_fleet.dart';
import 'package:haus_des_control/providers/provider_route.dart';
import 'package:haus_des_control/providers/provider_tasks.dart';
import 'package:haus_des_control/translations/codegen_loader.g.dart';
import 'package:provider/provider.dart';

import 'admin/screens/screen_admin_dashboard.dart';
import 'core/theme/app_theme.dart';
import 'layouts/bottom_nav_bar.dart';
import 'providers/provider_branches.dart';
import 'providers/provider_control.dart';
import 'providers/provider_map.dart';
import 'providers/provider_panel.dart';
import 'providers/provider_report_photo.dart';
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
        ChangeNotifierProvider(create: (_) => ProviderAuth()),
        ChangeNotifierProvider(create: (_) => ProviderPanel()),
        ChangeNotifierProvider(create: (_) => ProviderBranches()),
        ChangeNotifierProvider(create: (_) => ProviderReportPhoto()),
        ChangeNotifierProvider(create: (_) => ProviderFleet()),
        ChangeNotifierProvider(create: (_) => ProviderTasks()),
        ChangeNotifierProvider(create: (_) => ProviderRoute()),
        ChangeNotifierProvider(create: (_) => ProviderControl()),
        ChangeNotifierProvider(create: (_) => BranchMapController()),
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
        home: AuthWrapper(),
        routes: AppRouter.routes,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderAuth>(
      builder: (context, providerAuth, _) {
        final currentUser = providerAuth.currentUser;

        if (currentUser == null) {
          return const ScreenAuth();
        }

        final user = providerAuth.userModel;
        if (user != null) {
          return user.isAdmin ? AdminBottomNavBar() : ScreenBottomNavBar();
        }

        providerAuth.fetchUserModel().then((fetchedUser) {
          providerAuth.userModel = fetchedUser;
          (context as Element).markNeedsBuild();
        });

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
