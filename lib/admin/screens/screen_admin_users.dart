import 'package:flutter/material.dart';
import '../layouts/admin_layout.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Users Management',
      child: Center(child: Text('Users Management Screen')),
    );
  }
}
