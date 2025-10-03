import 'package:flutter/material.dart';
import '../layouts/admin_layout.dart';

class AdminBranchesScreen extends StatelessWidget {
  const AdminBranchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Branches Management',
      child: Center(child: Text('Branches Management Screen')),
    );
  }
}
