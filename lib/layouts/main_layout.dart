import 'package:flutter/material.dart';
import 'package:haus_des_control/screens/user/panel_page.dart';

import '../routes/app_routes.dart';
import '../widgets/custom_app_bar.dart';

/// Main layout widget that contains the app bar and body content
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  String _currentRoute = RouteNames.panel;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_navigatorKey.currentState?.canPop() ?? false) {
          _navigatorKey.currentState?.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          currentRoute: _currentRoute,
          onRouteSelected: _handleRouteSelection,
        ),
        body: Navigator(
          key: _navigatorKey,
          initialRoute: RouteNames.panel,
          onGenerateRoute: _onGenerateRoute,
        ),
      ),
    );
  }

  void _handleRouteSelection(String route) {
    setState(() => _currentRoute = route);
    _navigatorKey.currentState?.pushReplacementNamed(route);
  }

  Route _onGenerateRoute(RouteSettings settings) {
    Widget page;
    if (AppRouter.routes.containsKey(settings.name)) {
      page = AppRouter.routes[settings.name]!(context);
    } else {
      page = const PanelPage();
    }

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      settings: settings,
    );
  }
}
