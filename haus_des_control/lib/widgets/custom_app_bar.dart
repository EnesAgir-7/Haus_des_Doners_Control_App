import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentRoute;
  final Function(String) onRouteSelected;

  const CustomAppBar({
    super.key,
    required this.currentRoute,
    required this.onRouteSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(120); // AppBar + Navigation height

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryRed,
      child: SafeArea(
        child: Column(
        children: [
          // Logo and title section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 36,
                      ),
                    ),
                    
                  ],
                ),
              ],
            ),
          ),
          
          // Navigation bar
          Container(
            color: AppColors.primaryDark,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildNavLink(context, 'Panel', RouteNames.panel),
                  _buildNavLink(context, 'Şubeler', RouteNames.subsidiaries),
                  _buildNavLink(context, 'Kontrol', RouteNames.control),
                  _buildNavLink(context, 'Rota', RouteNames.route),
                  _buildNavLink(context, 'Filo', RouteNames.fleet),
                  _buildNavLink(context, 'Görevler', RouteNames.tasks),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildNavLink(BuildContext context, String title, String route) {
    bool isCurrentRoute = currentRoute == route;
    
    return TextButton(
      onPressed: () => onRouteSelected(route),
      style: TextButton.styleFrom(
        backgroundColor: isCurrentRoute ? AppColors.primaryRed : Colors.transparent,
        foregroundColor: isCurrentRoute ? AppColors.white : AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        textStyle: const TextStyle(fontSize: 14),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Köşeleri düz yapıyor
        ),
      ),
      child: Text(title),
    );
  }
}