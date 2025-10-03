import 'package:flutter/material.dart';
import '../layouts/admin_layout.dart';

class AdminTasksScreen extends StatelessWidget {
  const AdminTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Tasks Management',
      child: Center(child: Text('Tasks Management Screen')),
    );
  }
}
