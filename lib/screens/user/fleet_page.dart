import 'package:flutter/material.dart';

class FleetPage extends StatefulWidget {
  const FleetPage({super.key});

  @override
  State<FleetPage> createState() => _FleetPageState();
}

class _FleetPageState extends State<FleetPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Panel Page'),
      ),
    );
  }
}