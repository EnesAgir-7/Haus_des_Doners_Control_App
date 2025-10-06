import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/widgets/statistic_card.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/provider_route.dart';
import '../../translations/locale_keys.g.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<ProviderRoute>(context, listen: false).fetchTodaysRoute();
    // });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes in the provider
    final routeProvider = Provider.of<ProviderRoute>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.route_outlined,
                    color: Colors.lightBlueAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LocaleKeys.upcoming_routes.tr(),
                    style: const TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              Expanded(child: _buildRouteContent(routeProvider)),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the main content based on the provider's state
  Widget _buildRouteContent(ProviderRoute provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Text(
          '${provider.errorMessage}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (provider.allRoute == null || provider.stops.isEmpty) {
      return Center(
        child: Text(
          LocaleKeys.no_route_today.tr(),
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: () async {
        await provider.fetchAllRoutes();
      },
      child: ListView.separated(
        physics: AlwaysScrollableScrollPhysics(),
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemCount: provider.stops.length,
        itemBuilder: (context, index) {
          final stop = provider.stops[index];

          return StatisticCard(stop: stop);
        },
      ),
    );
  }
}
