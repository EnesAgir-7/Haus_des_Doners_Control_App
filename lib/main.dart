import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_branches.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_users.dart';
import 'package:haus_des_control/Modules/admin/admin_providers/provider_admin_vehicle.dart';
import 'package:haus_des_control/Modules/admin/screens/admin_bottom_nav_bar.dart';
import 'package:haus_des_control/Modules/inspector/providers/provider_route.dart';
import 'package:haus_des_control/Modules/inspector/providers/provider_tasks.dart';
import 'package:haus_des_control/Modules/inspector/providers/provider_vehicle.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:haus_des_control/translations/codegen_loader.g.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'Modules/admin/admin_providers/provider_admin_announcements.dart';
import 'Modules/admin/admin_providers/provider_admin_bottombar.dart';
import 'Modules/admin/admin_providers/provider_admin_documents.dart';
import 'Modules/admin/admin_providers/provider_admin_inspections.dart';
import 'Modules/admin/admin_providers/provider_admin_tasks.dart';
import 'Modules/admin/admin_providers/provider_admin_trainings.dart';
import 'Modules/admin/admin_providers/provider_admin_update_requests.dart';
import 'Modules/branch/branch_providers/provider_branch_bottom_navbar.dart';
import 'Modules/branch/branch_providers/provider_branch_dashboard.dart';
import 'Modules/branch/branch_providers/provider_branch_inspections.dart';
import 'Modules/branch/branch_providers/provider_branch_update_request.dart';
import 'Modules/branch/screens/branch_screen_bottom_navbar.dart';
import 'Modules/inspector/providers/provider_auth_new.dart';
import 'Modules/inspector/providers/provider_bottom_nav_bar.dart';
import 'Modules/inspector/providers/provider_branches.dart';
import 'Modules/inspector/providers/provider_control.dart';
import 'Modules/inspector/providers/provider_inspections.dart';
import 'Modules/inspector/providers/provider_map.dart';
import 'Modules/inspector/providers/provider_panel.dart';
import 'Modules/inspector/providers/provider_panel_old.dart';
import 'Modules/inspector/providers/provider_report_photo.dart';
import 'Modules/inspector/screens/bottom_nav_bar.dart';
import 'Modules/inspector/screens/screen_auth.dart';
import 'app_env.dart';
import 'common_services/fcm_helper.dart';
import 'common_services/remote_config_service.dart';
import 'core/constants/app_colors.dart';
import 'core/global_focus_manager.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';

//V2 Started
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// this is main

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.printEnvironment();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: AppEnvironment.firebaseOptions);
  }
  await RemoteConfigService().initialize();
  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.primaryDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  // Initialize FCM
  FCMHelper.instance.initialize(
    onMessageReceived: (RemoteMessage message) {
      // console('Message received: ${message.notification?.title}');
    },
    onMessageOpenedApp: (RemoteMessage message) {
      // console('Notification opened: ${message.data}');
      // Navigate based on message.data
    },
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((v) {
    runApp(
      EasyLocalization(
        path: 'assets/translations',
        assetLoader: const CodegenLoader(),
        supportedLocales: const [Locale('en'), Locale('de'), Locale('tr')],
        fallbackLocale: const Locale('tr'),
        saveLocale: true,
        startLocale: const Locale('tr'),
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
        ChangeNotifierProvider(create: (_) => ProviderPanelOld()),
        ChangeNotifierProvider(create: (_) => ProviderBranches()),
        ChangeNotifierProvider(create: (_) => ProviderReportPhoto()),
        ChangeNotifierProvider(create: (_) => ProviderVehicle()),
        ChangeNotifierProvider(create: (_) => ProviderTasks()),
        ChangeNotifierProvider(create: (_) => ProviderRoute()),
        ChangeNotifierProvider(create: (_) => ProviderControl()),
        ChangeNotifierProvider(create: (_) => BranchMapController()),
        ChangeNotifierProvider(create: (_) => ProviderAdminBranches()),
        ChangeNotifierProvider(create: (_) => ProviderAdminVehicles()),
        ChangeNotifierProvider(create: (_) => ProviderAdminUsers()),
        ChangeNotifierProvider(create: (_) => ProviderBottomNavBar()),
        ChangeNotifierProvider(create: (_) => ProviderInspection()),
        ChangeNotifierProvider(create: (_) => AdminBottomNavProvider()),
        ChangeNotifierProvider(create: (_) => ProviderAdminInspections()),
        ChangeNotifierProvider(create: (_) => ProviderAdminTasks()),
        ChangeNotifierProvider(create: (_) => ProviderBranchDashboard()),
        ChangeNotifierProvider(create: (_) => ProviderBranchBottomNavBar()),
        ChangeNotifierProvider(create: (_) => ProviderBranchInspections()),
        ChangeNotifierProvider(create: (_) => AdminTrainingVideosProvider()),
        ChangeNotifierProvider(create: (_) => AdminDocumentsProvider()),
        ChangeNotifierProvider(create: (_) => BranchUpdateRequestProvider()),
        ChangeNotifierProvider(create: (_) => AdminUpdateRequestProvider()),
        ChangeNotifierProvider(create: (_) => AdminAnnouncementsProvider()),
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
          title: AppEnvironment.appName,
          theme: AppTheme.light,
          navigatorKey: navigatorKey,
          navigatorObservers: [GlobalFocusManager()],
          builder: (context, widget) {
            return SafeArea(
              bottom: Platform.isIOS ? false : true,
              top: false,
              child: ResponsiveBreakpoints.builder(
                child: ResponsiveScaledBox(
                  width: 480,
                  child: widget ?? Container(),
                ),
                breakpoints: [
                  const Breakpoint(start: 0, end: 600, name: MOBILE),
                  const Breakpoint(start: 601, end: 1024, name: TABLET),
                  const Breakpoint(start: 1025, end: 1920, name: DESKTOP),
                  const Breakpoint(
                    start: 1921,
                    end: double.infinity,
                    name: '4K',
                  ),
                ],
              ),
            );
          },

          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: const AuthWrapper(),
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
      builder: (context, auth, _) {
        if (auth.userModel == null) return const ScreenAuth();

        loggedInUser = auth.userModel;

        switch (auth.userModel!.role) {
          case AppConstants.admin:
            return AdminBottomNavBar();

          case AppConstants.branch:
            return BranchScreenBottomNavBar();

          case AppConstants.inspector:
          default:
            return ScreenBottomNavBar();
        }
      },
    );
  }
}
