import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/widgets/custom_toast.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/provider_fleet.dart';
import '../../translations/locale_keys.g.dart';

class FleetPage extends StatefulWidget {
  const FleetPage({super.key});

  @override
  State<FleetPage> createState() => _FleetPageState();
}

class _FleetPageState extends State<FleetPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProviderFleet>();
      if (provider.currentUser?.isAdmin ?? false) {
        provider.initializeAdmin();
      } else {
        provider.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProviderFleet>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: AppColors.primaryRed,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading fleet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.errorMessage!,
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show admin view or inspector view
          return RefreshIndicator(
            onRefresh: provider.refresh,
            color: AppColors.primaryRed,
            backgroundColor: AppColors.lightBlack,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      icon: Icons.local_shipping,
                      title: LocaleKeys.fleet_management.tr(),
                    ),
                    const SizedBox(height: 12),

                    // Show current vehicle if inspector has one
                    if (provider.hasAssignedVehicle) ...[
                      _CurrentVehicleCard(provider: provider),
                      const SizedBox(height: 16),
                      _VehicleDetailsCard(provider: provider),
                      // const SizedBox(height: 16),
                      // _ActionButtons(provider: provider),
                      const SizedBox(height: 24),
                    ] else ...[
                      _NoVehicleCard(),
                      const SizedBox(height: 24),
                    ],

                    // _SectionTitle(
                    //   icon: Icons.directions_car,
                    //   title: LocaleKeys.other_controller_vehicles.tr(),
                    // ),
                    // const SizedBox(height: 12),
                    // _OtherVehiclesList(provider: provider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryRed, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

// -------------------- No Vehicle Card --------------------
class _NoVehicleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 60,
              color: Colors.white38,
            ),
            SizedBox(height: 12),
            Text(
              'No vehicle assigned',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Please contact admin for vehicle assignment',
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- Current Vehicle Card --------------------
class _CurrentVehicleCard extends StatelessWidget {
  final ProviderFleet provider;
  const _CurrentVehicleCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key, color: AppColors.primaryRed, size: 18),
              const SizedBox(width: 6),
              Text(
                LocaleKeys.current_rented_vehicle.tr(),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            provider.currentUser?.name ?? 'Inspector',
            style: const TextStyle(color: AppColors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// -------------------- Vehicle Details Card --------------------
class _VehicleDetailsCard extends StatelessWidget {
  final ProviderFleet provider;
  const _VehicleDetailsCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final vehicle = provider.assignedVehicle;
    if (vehicle == null) return SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VehicleInfo(model: vehicle.model, plate: vehicle.plate),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _StatBox(
                  value: NumberFormat('#,###').format(vehicle.currentKm),
                  label: LocaleKeys.current_km.tr(),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatBox(
                  value: NumberFormat('#,###').format(vehicle.maxKm),
                  label: LocaleKeys.max_km.tr(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RemainingKm(vehicle: vehicle, provider: provider),
          const SizedBox(height: 16),
          _ReturnDate(vehicle: vehicle),
        ],
      ),
    );
  }
}

// -------------------- Vehicle Info --------------------
class _VehicleInfo extends StatelessWidget {
  final String model;
  final String plate;

  const _VehicleInfo({required this.model, required this.plate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.directions_car, color: AppColors.white, size: 28),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "Plate: $plate",
                style: TextStyle(color: AppColors.lightGrey, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------- Stat Box --------------------
class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.white, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// -------------------- Remaining KM --------------------
class _RemainingKm extends StatelessWidget {
  final dynamic vehicle;
  final ProviderFleet provider;
  const _RemainingKm({required this.vehicle, required this.provider});

  @override
  Widget build(BuildContext context) {
    final progress = vehicle.usagePercent / 100.0;
    final progressColor = _getProgressColor(vehicle.usagePercent);

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleKeys.remaining_km.tr(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                tooltip: "Update KM",
                onPressed: () => _showUpdateKmDialog(context, provider),
                icon: Icon(Icons.edit, color: AppColors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "${NumberFormat('#,###').format(vehicle.remainingKm)} km",
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.lightRed,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${vehicle.usagePercent}% used",
            style: const TextStyle(color: AppColors.lightGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(int percent) {
    if (percent >= 95) return Colors.red;
    if (percent >= 70) return Colors.amber;
    return Colors.green;
  }
}

// -------------------- Return Date --------------------
class _ReturnDate extends StatelessWidget {
  final dynamic vehicle;
  const _ReturnDate({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final daysUntil = vehicle.nextServiceDue.difference(DateTime.now()).inDays;
    final isUrgent = daysUntil <= 5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Service Due",
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMMM yyyy').format(vehicle.nextServiceDue),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              if (isUrgent)
                Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: AppColors.primaryRed,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      daysUntil > 0
                          ? "$daysUntil days left"
                          : "${daysUntil.abs()} days overdue",
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  "$daysUntil days until service",
                  style: const TextStyle(color: Colors.green, fontSize: 13),
                ),
            ],
          ),
        ),
        const Icon(Icons.calendar_month, color: AppColors.white, size: 32),
      ],
    );
  }
}

void _showUpdateKmDialog(BuildContext context, ProviderFleet provider) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.lightBlack,
      title: Text('Update Kilometers', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current: ${NumberFormat('#,###').format(provider.currentKm)} km',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 16),
          TextField(
            controller: provider.kmController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'New Kilometers',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: 'Enter new KM',
              hintStyle: TextStyle(color: Colors.white38),
              filled: true,
              fillColor: AppColors.lightRed,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (provider.errorMessage != null) ...[
            SizedBox(height: 12),
            Text(
              provider.errorMessage!,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () async {
            final success = await provider.updateKmFromController();
            if (success) {
              Navigator.pop(context);
              showSnakBarr(context, 'Kilometers updated successfully');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
          ),
          child: Text('Update'),
        ),
      ],
    ),
  );
}

// -------------------- Other Vehicles List --------------------
// class _OtherVehiclesList extends StatelessWidget {
//   final ProviderFleet provider;
//   const _OtherVehiclesList({required this.provider});

//   @override
//   Widget build(BuildContext context) {
//     // For inspectors, show all vehicles. For admins might show different view
//     final vehicles = provider.allVehicles
//         .where(
//           (v) =>
//               v.assignedInspectorId != null &&
//               v.assignedInspectorId != provider.currentUser?.id,
//         )
//         .toList();

//     if (vehicles.isEmpty) {
//       return Container(
//         padding: EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: AppColors.lightBlack,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Center(
//           child: Text(
//             'No other vehicles',
//             style: TextStyle(color: Colors.white54),
//           ),
//         ),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: vehicles.length,
//       itemBuilder: (context, index) {
//         final vehicle = vehicles[index];
//         return _OtherVehicleCard(vehicle: vehicle);
//       },
//     );
//   }
// }

// -------------------- Action Buttons --------------------
// class _ActionButtons extends StatelessWidget {
//   final ProviderFleet provider;

//   const _ActionButtons({required this.provider});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: AppButton(
//             text: LocaleKeys.update_km.tr(),
//             isLoading: provider.isUpdating,
//             onPressed: () => _showUpdateKmDialog(context, provider),
//             backgroundColor: AppColors.lightRed,
//           ),
//         ),
//       ],
//     );
//   }

// }


// -------------------- Other Vehicle Card --------------------
// class _OtherVehicleCard extends StatelessWidget {
//   final dynamic vehicle;

//   const _OtherVehicleCard({required this.vehicle});

//   @override
//   Widget build(BuildContext context) {
//     final progress = vehicle.usagePercent / 100.0;
//     final progressColor = _getProgressColor(vehicle.usagePercent);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: AppColors.lightBlack,
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             vehicle.assignedInspectorName ?? 'Unassigned',
//             style: const TextStyle(
//               color: AppColors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             vehicle.plate,
//             style: const TextStyle(color: AppColors.lightGrey, fontSize: 13),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "KM: ${NumberFormat('#,###').format(vehicle.currentKm)} / ${NumberFormat('#,###').format(vehicle.maxKm)}",
//             style: const TextStyle(color: AppColors.white, fontSize: 13),
//           ),
//           const SizedBox(height: 6),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(6),
//             child: LinearProgressIndicator(
//               value: progress,
//               minHeight: 6,
//               backgroundColor: AppColors.lightRed,
//               valueColor: AlwaysStoppedAnimation(progressColor),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Service: ${DateFormat('dd MMM').format(vehicle.nextServiceDue)}",
//             style: const TextStyle(color: AppColors.lightGrey, fontSize: 13),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getProgressColor(int percent) {
//     if (percent >= 95) return Colors.red;
//     if (percent >= 70) return Colors.amber;
//     return Colors.green;
//   }
// }



















///////////////////////////////////////////////////////////





// class FleetPage extends StatelessWidget {
//   const FleetPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _SectionTitle(
//                 icon: Icons.local_shipping,
//                 title: LocaleKeys.fleet_management.tr(),
//               ),
//               const SizedBox(height: 12),
//               const _CurrentVehicleCard(),
//               const SizedBox(height: 16),
//               const _VehicleDetailsCard(),
//               const SizedBox(height: 24),
//               _SectionTitle(
//                 icon: Icons.directions_car,
//                 title: LocaleKeys.other_controller_vehicles.tr(),
//               ),
//               const SizedBox(height: 12),
//               const _OtherVehiclesList(),
//               const SizedBox(height: 16),
//               const _ActionButtons(isUpdating: false, isChangingVehicle: false),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _SectionTitle extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   const _SectionTitle({required this.icon, required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(icon, color: AppColors.primaryRed, size: 18),
//         const SizedBox(width: 6),
//         Text(
//           title,
//           style: const TextStyle(
//             color: AppColors.primaryRed,
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//       ],
//     );
//   }
// }

// // -------------------- Current Vehicle Card --------------------
// class _CurrentVehicleCard extends StatelessWidget {
//   const _CurrentVehicleCard();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppColors.lightBlack,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.primaryRed),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.vpn_key, color: AppColors.primaryRed, size: 18),
//               const SizedBox(width: 6),
//               Text(
//                 LocaleKeys.current_rented_vehicle.tr(),
//                 style: const TextStyle(
//                   color: AppColors.primaryRed,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 15,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             LocaleKeys.controller_name.tr(),
//             style: const TextStyle(color: AppColors.white, fontSize: 13),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // -------------------- Vehicle Details Card --------------------
// class _VehicleDetailsCard extends StatelessWidget {
//   const _VehicleDetailsCard();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.lightBlack,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const _VehicleInfo(),
//           const SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children:  [
//               Expanded(
//                 child: _StatBox(
//                   value: "15,420",
//                   label: LocaleKeys.current_km.tr(),
//                 ),
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 child: _StatBox(value: "25,000", label: LocaleKeys.max_km.tr()),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           const _RemainingKm(),
//           const SizedBox(height: 16),
//           const _ReturnDate(),
//         ],
//       ),
//     );
//   }
// }

// // -------------------- Vehicle Info --------------------
// class _VehicleInfo extends StatelessWidget {
//   const _VehicleInfo();

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: const [
//         Icon(Icons.directions_car, color: AppColors.white, size: 28),
//         SizedBox(width: 8),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Ford Transit Connect",
//               style: TextStyle(
//                 color: AppColors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             Text(
//               "Plaka: 34 ABC 1234",
//               style: TextStyle(color: AppColors.lightGrey, fontSize: 13),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// // -------------------- Stat Box --------------------
// class _StatBox extends StatelessWidget {
//   final String value;
//   final String label;

//   const _StatBox({required this.value, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 140,
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       decoration: BoxDecoration(
//         color: AppColors.lightRed,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Text(
//             value,
//             style: const TextStyle(
//               color: AppColors.primaryRed,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: const TextStyle(color: AppColors.white, fontSize: 13),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // -------------------- Remaining KM --------------------
// class _RemainingKm extends StatelessWidget {
//   const _RemainingKm();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: AppColors.lightRed,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             LocaleKeys.remaining_km.tr(),
//             style: const TextStyle(
//               color: AppColors.white,
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             LocaleKeys.remaining_km_value.tr(),
//             style: const TextStyle(
//               color: AppColors.primaryRed,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 6),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: const LinearProgressIndicator(
//               value: 0.62,
//               minHeight: 8,
//               backgroundColor: AppColors.lightRed,
//               valueColor: AlwaysStoppedAnimation(AppColors.primaryRed),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             LocaleKeys.used_percentage.tr(),
//             style: const TextStyle(color: AppColors.lightGrey, fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // -------------------- Return Date --------------------
// class _ReturnDate extends StatelessWidget {
//   const _ReturnDate();

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               LocaleKeys.return_date.tr(),
//               style: const TextStyle(
//                 color: AppColors.primaryRed,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               LocaleKeys.return_date_value.tr(),
//               style: const TextStyle(
//                 color: AppColors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 const Icon(
//                   Icons.warning,
//                   color: AppColors.primaryRed,
//                   size: 16,
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   LocaleKeys.days_left.tr(),
//                   style: const TextStyle(
//                     color: AppColors.primaryRed,
//                     fontSize: 13,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         const Icon(Icons.calendar_month, color: AppColors.white, size: 32),
//       ],
//     );
//   }
// }

// // -------------------- Other Vehicles List --------------------
// class _OtherVehiclesList extends StatelessWidget {
//   const _OtherVehiclesList();

//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       children:  [
//         _OtherVehicleCard(
//           name: LocaleKeys.vehicle_ahmet.tr(),
//           plate: LocaleKeys.plate_ahmet.tr(),
//           currentKm: 8500,
//           maxKm: 20000,
//           returnDate: "22 Ekim",
//           progressColor: Colors.green,
//         ),
//         _OtherVehicleCard(
//           name: LocaleKeys.vehicle_fatma.tr(),
//           plate: LocaleKeys.plate_fatma.tr(),
//           currentKm: 18200,
//           maxKm: 25000,
//           returnDate: "30 Ekim",
//           progressColor: Colors.amber,
//         ),
//         _OtherVehicleCard(
//           name: LocaleKeys.vehicle_osman.tr(),
//           plate: LocaleKeys.plate_osman.tr(),
//           currentKm: 22800,
//           maxKm: 24000,
//           returnDate: "12 Ekim",
//           progressColor: AppColors.primaryRed,
//         ),
//         _OtherVehicleCard(
//           name: LocaleKeys.vehicle_zehra.tr(),
//           plate: LocaleKeys.plate_zehra.tr(),
//           currentKm: 5300,
//           maxKm: 18000,
//           returnDate: "05 Kasım",
//           progressColor: Colors.green,
//         ),
//       ],
//     );
//   }
// }

// // -------------------- Action Buttons --------------------
// class _ActionButtons extends StatelessWidget {
//   final bool isUpdating;
//   final bool isChangingVehicle;

//   const _ActionButtons({
//     this.isUpdating = false,
//     this.isChangingVehicle = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: AppButton(
//             text: LocaleKeys.update_km.tr(),
//             isLoading: isUpdating,
//             onPressed: () {},
//             backgroundColor: AppColors.lightRed,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: AppButton(
//             text: LocaleKeys.change_vehicle.tr(),
//             isLoading: isChangingVehicle,
//             onPressed: () {},
//             backgroundColor: AppColors.primaryRed,
//           ),
//         ),
//       ],
//     );
//   }
// }

// // -------------------- Other Vehicle Card --------------------

// class _OtherVehicleCard extends StatelessWidget {
//   final String name;
//   final String plate;
//   final int currentKm;
//   final int maxKm;
//   final String returnDate;
//   final Color progressColor;

//   const _OtherVehicleCard({
//     required this.name,
//     required this.plate,
//     required this.currentKm,
//     required this.maxKm,
//     required this.returnDate,
//     required this.progressColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final progress = currentKm / maxKm;
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: AppColors.lightBlack,
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             name,
//             style: const TextStyle(
//               color: AppColors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             plate,
//             style: const TextStyle(color: AppColors.lightGrey, fontSize: 13),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "KM: $currentKm / $maxKm",
//             style: const TextStyle(color: AppColors.white, fontSize: 13),
//           ),
//           const SizedBox(height: 6),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(6),
//             child: LinearProgressIndicator(
//               value: progress,
//               minHeight: 6,
//               backgroundColor: AppColors.lightRed,
//               valueColor: AlwaysStoppedAnimation(progressColor),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "İade: $returnDate",
//             style: const TextStyle(color: AppColors.lightGrey, fontSize: 13),
//           ),
//         ],
//       ),
//     );
//   }
// }
