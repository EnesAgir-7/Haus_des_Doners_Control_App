import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/vehicle_card.dart';
import '../../providers/provider_admin_fleet.dart';
import '../../translations/locale_keys.g.dart';

class AdminFleetScreen extends StatefulWidget {
  const AdminFleetScreen({super.key});

  @override
  State<AdminFleetScreen> createState() => _AdminFleetScreenState();
}

class _AdminFleetScreenState extends State<AdminFleetScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProviderAdminFleet>().loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: LocaleKeys.search.tr(),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              context.read<ProviderAdminFleet>().setSearchQuery(value);
            },
          ),
        ),
        Expanded(
          child: Consumer<ProviderAdminFleet>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${provider.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.loadData(),
                        child: Text(LocaleKeys.retry.tr()),
                      ),
                    ],
                  ),
                );
              }

              final vehicles = provider.vehicles;
              if (vehicles.isEmpty) {
                if (_searchController.text.isNotEmpty) {
                  return Center(child: Text(LocaleKeys.no_branches_found.tr()));
                }
                return Center(
                  child: Text(LocaleKeys.no_branches_available.tr()),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadData(),
                child: ListView.builder(
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return VehicleCard(vehicle: vehicle);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
