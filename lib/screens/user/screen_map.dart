import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:haus_des_control/providers/provider_branches.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/branch_model.dart';
import '../../providers/provider_map.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_app_bar.dart';

class BranchMapScreen extends StatefulWidget {
  final List<BranchModel> branches;

  const BranchMapScreen({super.key, required this.branches});

  @override
  State<BranchMapScreen> createState() => _BranchMapScreenState();
}

class _BranchMapScreenState extends State<BranchMapScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the controller with branches after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<BranchMapController>();
      controller.initializeBranches(widget.branches);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BranchMapController>(
      builder: (context, controller, _) {
        // Show loading or empty state if no branches
        if (controller.branches.isEmpty) {
          return Scaffold(
            appBar: CustomAppBar(showLogout: false, showLang: false),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: CustomAppBar(showLogout: false, showLang: false),
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    controller.branches[0].gps.latitude,
                    controller.branches[0].gps.longitude,
                  ),
                  zoom: 14,
                ),
                onMapCreated: controller.setMapController,
                markers: controller.markers.values.toSet(),
                zoomControlsEnabled: false,
                myLocationButtonEnabled: true,
                compassEnabled: true,
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                height: 160,
                child: PageView.builder(
                  controller: controller.pageController,
                  itemCount: controller.branches.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: controller.onPageChanged,
                  itemBuilder: (context, index) {
                    final branch = controller.branches[index];
                    return _branchCard(branch);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _branchCard(BranchModel branch) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.lightBlack,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  // Uncomment to show branch image
                  // if (branch.imageUrl != null && branch.imageUrl!.isNotEmpty)
                  //   ClipRRect(
                  //     borderRadius: BorderRadius.circular(8),
                  //     child: Image.network(
                  //       branch.imageUrl!,
                  //       width: 60,
                  //       height: 60,
                  //       fit: BoxFit.cover,
                  //       errorBuilder: (_, __, ___) => const Icon(
                  //         Icons.apartment,
                  //         size: 50,
                  //         color: Colors.white24,
                  //       ),
                  //     ),
                  //   ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          branch.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          branch.address,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                height: 40,
                child: Row(
                  children: [
                    // Expanded(
                    //   child: Consumer<ProviderBranches>(
                    //     builder: (context, branchContr, child) {
                    //       return AppButton(
                    //         isLoading: branchContr.isLoading,
                    //         text: branch.isRouteAssigned
                    //             ? "Un Assign"
                    //             : "Assign to Me",
                    //         onPressed: () async {
                    //           if (branch.isRouteAssigned) {
                    //             branchContr.unAssignBranchToMe(
                    //               branchId: branch.id,
                    //               context: context,
                    //             );
                    //           } else {
                    //             // show date picker before assigning
                    //             final DateTime? pickedDate =
                    //                 await showDatePicker(
                    //                   locale: context.locale,
                    //                   context: context,
                    //                   initialDate: DateTime.now(),
                    //                   firstDate: DateTime.now(),
                    //                   lastDate: DateTime.now().add(
                    //                     const Duration(days: 365),
                    //                   ),
                    //                 );

                    //             if (pickedDate != null) {
                    //               // format the slot however you want
                    //               final String timeSlot =
                    //                   //  Timestamp.fromDate(
                    //                   //   pickedDate,
                    //                   // );
                    //                   "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";

                    //               branchContr.assignBranchToMe(
                    //                 branch: branch,
                    //                 timeSlot: timeSlot,
                    //                 context: context,
                    //               );
                    //             }
                    //           }
                    //         },
                    //         backgroundColor: branch.isRouteAssigned
                    //             ? AppColors.primaryRed
                    //             : AppColors.amber,
                    //         textStyle: TextStyle(
                    //           fontSize: 11,
                    //           color: branch.isRouteAssigned
                    //               ? Colors.white
                    //               : AppColors.primaryDark,
                    //         ),
                    //         padding: const EdgeInsets.symmetric(vertical: 8),
                    //         borderRadius: 10,
                    //       );
                    //     },
                    //   ),
                    // ),
                    Expanded(
                      // Listen to both providers to get real-time updates
                      child: Consumer2<ProviderBranches, BranchMapController>(
                        builder: (context, branchContr, mapContr, child) {
                          // Get the updated branch from map controller
                          final updatedBranch = mapContr.branches.firstWhere(
                            (b) => b.id == branch.id,
                            orElse: () => branch,
                          );

                          return AppButton(
                            isLoading: branchContr.isLoading,
                            text: updatedBranch.isRouteAssigned
                                ? "Un Assign"
                                : "Assign to Me",
                            onPressed: () async {
                              if (updatedBranch.isRouteAssigned) {
                                // Unassign
                                final success = await branchContr
                                    .unAssignBranchToMe(
                                      branchId: updatedBranch.id,
                                      context: context,
                                    );

                                if (success) {
                                  // Update marker to red
                                  mapContr.updateBranchMarker(
                                    updatedBranch.id,
                                    false,
                                  );
                                }
                              } else {
                                // Show date picker before assigning
                                final DateTime? pickedDate =
                                    await showDatePicker(
                                      locale: context.locale,
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );

                                if (pickedDate != null) {
                                  final String timeSlot =
                                      "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";

                                  final success = await branchContr
                                      .assignBranchToMe(
                                        branchId: branch.id,
                                        branchName: branch.name,
                                        timeSlot: timeSlot,
                                        context: context,
                                      );

                                  if (success) {
                                    // Update marker to green
                                    mapContr.updateBranchMarker(
                                      updatedBranch.id,
                                      true,
                                    );
                                  }
                                }
                              }
                            },
                            backgroundColor: updatedBranch.isRouteAssigned
                                ? AppColors.primaryRed
                                : AppColors.amber,
                            textStyle: TextStyle(
                              fontSize: 11,
                              color: updatedBranch.isRouteAssigned
                                  ? Colors.white
                                  : AppColors.primaryDark,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            borderRadius: 10,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        text: "Submit Inspection",
                        onPressed: () {},
                        backgroundColor: AppColors.primaryRed,
                        textStyle: const TextStyle(fontSize: 11),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        borderRadius: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
