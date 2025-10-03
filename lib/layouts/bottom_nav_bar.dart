import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/widgets/custom_app_bar.dart';

import '../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../translations/locale_keys.g.dart';

class ScreenBottomNavBar extends StatefulWidget {
  const ScreenBottomNavBar({super.key});

  @override
  State<ScreenBottomNavBar> createState() => _ScreenBottomNavBarState();
}

class _ScreenBottomNavBarState extends State<ScreenBottomNavBar> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // build all screens once so their state is preserved
    _screens = [
      AppRouter.routes[RouteNames.panel]!(context),
      AppRouter.routes[RouteNames.subsidiaries]!(context),
      AppRouter.routes[RouteNames.route]!(context),
      AppRouter.routes[RouteNames.fleet]!(context),
      AppRouter.routes[RouteNames.tasks]!(context),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AppColors.primaryDark,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: LocaleKeys.panel.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.apartment),
            label: LocaleKeys.my_branches.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.alt_route),
            label: LocaleKeys.route.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.car_rental),
            label: LocaleKeys.fleet.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.task),
            label: LocaleKeys.tasks.tr(),
          ),
        ],
      ),
    );
  }
}

/// Main layout widget that contains the app bar and body content
// class MainLayout extends StatefulWidget {
//   const MainLayout({super.key});

//   @override
//   State<MainLayout> createState() => _MainLayoutState();
// }

// class _MainLayoutState extends State<MainLayout> {
//   final _navigatorKey = GlobalKey<NavigatorState>();
//   String _currentRoute = RouteNames.panel;

//   @override
//   Widget build(BuildContext context) {
//     // ignore: deprecated_member_use
//     return WillPopScope(
//       onWillPop: () async {
//         if (_navigatorKey.currentState?.canPop() ?? false) {
//           _navigatorKey.currentState?.pop();
//           return false;
//         }
//         return true;
//       },
//       child: Scaffold(
//         appBar: CustomAppBar(
//           currentRoute: _currentRoute,
//           onRouteSelected: _handleRouteSelection,
//         ),
//         body: Navigator(
//           key: _navigatorKey,
//           initialRoute: RouteNames.panel,
//           onGenerateRoute: _onGenerateRoute,
//         ),
//       ),
//     );
//   }

//   void _handleRouteSelection(String route) {
//     setState(() => _currentRoute = route);
//     _navigatorKey.currentState?.pushReplacementNamed(route);
//   }

//   Route _onGenerateRoute(RouteSettings settings) {
//     Widget page;
//     if (AppRouter.routes.containsKey(settings.name)) {
//       page = AppRouter.routes[settings.name]!(context);
//     } else {
//       page = const PanelPage();
//     }

//     return PageRouteBuilder(
//       pageBuilder: (context, animation, secondaryAnimation) => page,
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         const begin = Offset(1.0, 0.0);
//         const end = Offset.zero;
//         const curve = Curves.easeInOut;
//         var tween = Tween(
//           begin: begin,
//           end: end,
//         ).chain(CurveTween(curve: curve));
//         var offsetAnimation = animation.drive(tween);
//         return SlideTransition(position: offsetAnimation, child: child);
//       },
//       settings: settings,
//     );
//   }
// }
