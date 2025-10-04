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
                    LocaleKeys.your_route_plan.tr(),
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
          'Hata: ${provider.errorMessage}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (provider.todaysRoute == null || provider.stops.isEmpty) {
      return const Center(
        child: Text(
          'Bugün için planlanmış bir rota bulunamadı.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: () async {
        await provider.fetchTodaysRoute();
      },
      child: ListView.separated(
        physics: AlwaysScrollableScrollPhysics(),
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemCount: provider.stops.length,
        itemBuilder: (context, index) {
          final stop = provider.stops[index];

          return StatisticCard(stop: stop);
        },
      ),
    );
  }
}
// class RoutePage extends StatelessWidget {
//   RoutePage({super.key});

//   final List<StatisticCard> scheduleList = [
//     StatisticCard(
//       time: "09:00 - 10:30",
//       title: "Haus des Döners - Beyoğlu",
//       status: "Tamamlandı",
//       subtitle: "",
//       statusColor: Colors.green,
//       icon: Icons.check_box,
//     ),
//     StatisticCard(
//       time: "11:00 - 12:30",
//       title: "Haus des Döners - Galata",
//       status: "Tamamlandı",
//       subtitle: "",
//       statusColor: Colors.green,
//       icon: Icons.check_box,
//     ),
//     StatisticCard(
//       time: "14:00 - 15:30",
//       title: "Haus des Döners - Şişli",
//       status: "Şu anki konum",
//       subtitle: "",
//       statusColor: Colors.pink,
//       icon: Icons.location_on,
//     ),
//     StatisticCard(
//       time: "16:00 - 17:30",
//       title: "Haus des Döners - Mecidiyeköy",
//       status: "Bekliyor",
//       subtitle: "",
//       statusColor: Colors.grey,
//       icon: Icons.hourglass_empty,
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.book, color: Colors.lightBlueAccent),
//                   SizedBox(width: 6),
//                   Text(
//                     LocaleKeys.today_route_plan.tr(),
//                     style: TextStyle(
//                       color: AppColors.primaryRed,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),

//               Container(height: 1, color: Colors.white24),
//               const SizedBox(height: 12),

//               Expanded(
//                 child: ListView.separated(
//                   separatorBuilder: (context, index) => SizedBox(height: 10),
//                   itemCount: scheduleList.length,
//                   itemBuilder: (context, index) {
//                     return scheduleList[index];
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
