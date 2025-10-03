import 'package:flutter/material.dart';
import '../layouts/admin_layout.dart';

class AdminFleetScreen extends StatelessWidget {
  const AdminFleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Fleet Management',
      child: Center(child: Text('Fleet Management Screen')),
    );
  }
}
