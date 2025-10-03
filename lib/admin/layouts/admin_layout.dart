import 'package:flutter/material.dart';

import '../widgets/admin_app_bar.dart';
import '../widgets/admin_navbar.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String title;

  const AdminLayout({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 768; // Tablet breakpoint

    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return Scaffold(
      appBar: AdminAppBar(
        currentRoute: currentRoute,
        onRouteSelected: (route) {
          Navigator.pushNamed(context, route);
        },
      ),
      // Show side navigation for tablet
      drawer: isTablet
          ? null
          : AdminNavBar(
              currentRoute: currentRoute,
              onRouteSelected: (route) {
                Navigator.pop(context); // Close drawer
                Navigator.pushNamed(context, route);
              },
            ),
      body: SafeArea(
        child: Row(
          children: [
            // Show permanent side navigation for tablet
            if (isTablet)
              AdminNavBar(
                currentRoute: currentRoute,
                onRouteSelected: (route) {
                  Navigator.pushNamed(context, route);
                },
              ),

            // Main content
            Expanded(
              child: Padding(padding: const EdgeInsets.all(16.0), child: child),
            ),
          ],
        ),
      ),
    );
  }
}
