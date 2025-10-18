import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haus_des_control/admin/layouts/admin_bottom_nav_bar.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/firebase_options.dart';
import 'package:haus_des_control/providers/provider_admin_branches.dart';
import 'package:haus_des_control/providers/provider_admin_fleet.dart';
import 'package:haus_des_control/providers/provider_admin_stats.dart';
import 'package:haus_des_control/providers/provider_admin_users.dart';
import 'package:haus_des_control/providers/provider_auth.dart';
import 'package:haus_des_control/providers/provider_fleet.dart';
import 'package:haus_des_control/providers/provider_route.dart';
import 'package:haus_des_control/providers/provider_tasks.dart';
import 'package:haus_des_control/translations/codegen_loader.g.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/global_focus_manager.dart';
import 'core/theme/app_theme.dart';
import 'layouts/bottom_nav_bar.dart';
import 'providers/provider_bottom_nav_bar.dart';
import 'providers/provider_branches.dart';
import 'providers/provider_control.dart';
import 'providers/provider_inspections.dart';
import 'providers/provider_map.dart';
import 'providers/provider_panel.dart';
import 'providers/provider_report_photo.dart';
import 'routes/app_routes.dart';
import 'screens/screen_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Initialize OneDrive
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // statusBarColor: Colors.transparent, // Transparent status bar
      // statusBarIconBrightness: Brightness.light, // Light icons
      systemNavigationBarColor: AppColors.primaryDark, // 👈 Your desired color
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

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
        ChangeNotifierProvider(create: (_) => ProviderAdminBranches()),
        ChangeNotifierProvider(create: (_) => ProviderAdminFleet()),
        ChangeNotifierProvider(create: (_) => ProviderAdminStats()),
        ChangeNotifierProvider(create: (_) => ProviderAdminUsers()),
        ChangeNotifierProvider(create: (_) => ProviderBottomNavBar()),
        ChangeNotifierProvider(create: (_) => ProviderInspection()),
      ],
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          debugShowCheckedModeBanner: false,
          title: 'Haus des Control',
          theme: AppTheme.light,
          navigatorKey: navigatorKey,
          navigatorObservers: [GlobalFocusManager()],

          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: AuthWrapper(),
          routes: AppRouter.routes,
          localeListResolutionCallback: (deviceLocales, supportedLocales) {
            if (deviceLocales != null) {
              for (var deviceLocale in deviceLocales) {
                for (var locale in supportedLocales) {
                  if (locale.languageCode == deviceLocale.languageCode) {
                    return locale;
                  }
                }
              }
            }
            return context.fallbackLocale;
          },
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale != null) {
              for (var locale in supportedLocales) {
                if (locale.languageCode == deviceLocale.languageCode) {
                  return locale;
                }
              }
            }
            return context.fallbackLocale;
          },
        ),
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

        // Not logged in → show login screen
        if (currentUser == null) return const ScreenAuth();

        // Logged in but user model is still loading
        if (providerAuth.userModel == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // User model ready → show relevant dashboard
        final user = providerAuth.userModel!;
        loggedInUser = user; // keep global in sync

        return user.isAdmin ? const AdminBottomNavBar() : ScreenBottomNavBar();
      },
    );
  }
}
