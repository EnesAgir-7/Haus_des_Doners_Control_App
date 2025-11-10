import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:haus_des_control/Modules/inspector/providers/provider_branches.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/branch_model.dart';
import '../providers/provider_map.dart';
import '../widgets/app_button.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/route_picker_dialog.dart';
import 'screen_submit_report.dart';

class BranchMapScreen extends StatefulWidget {
  // final List<BranchModel> branches;

  const BranchMapScreen({super.key});

  @override
  State<BranchMapScreen> createState() => _BranchMapScreenState();
}

class _BranchMapScreenState extends State<BranchMapScreen> {
  ProviderBranches? _provider;
  BranchMapController? _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the controller with branches after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = context.read<BranchMapController>();
      _provider = context.read<ProviderBranches>();

      _controller?.initializeBranches(_provider!.branches);
      _provider?.addListener(_onBranchesChanged);
    });
  }

  void _onBranchesChanged() {
    if (!mounted) return;
    _controller?.updateBranches(_provider!.branches);
  }

  @override
  void dispose() {
    _provider?.removeListener(_onBranchesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BranchMapController, ProviderBranches>(
      builder: (context, controller, brr, _) {
        // Show loading or empty state if no branches
        if (controller.branches.isEmpty) {
          return const Scaffold(
            appBar: CustomAppBar(),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: const CustomAppBar(),
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
    return Consumer<ProviderBranches>(
      builder: (context, brrl, child) {
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
                            if (branch.stop?.timeSlot != null)
                              Text(
                                "${LocaleKeys.nextInspection.tr()}: ${branch.isNextInspectionToday ? LocaleKeys.today.tr() : branch.stop?.timeSlot.toString()} (${branch.daysUntilNextInspection} ${LocaleKeys.daysLeft.tr()})",
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
                        Expanded(
                          // Listen to both providers to get real-time updates
                          child: Consumer2<ProviderBranches, BranchMapController>(
                            builder: (context, branchContr, mapContr, child) {
                              // Get the updated branch from map controller
                              final updatedBranch = mapContr.branches
                                  .firstWhere(
                                    (b) => b.id == branch.id,
                                    orElse: () => branch,
                                  );

                              return AppButton(
                                isLoading: branchContr.isLoading,
                                text: updatedBranch.stop != null
                                    ? LocaleKeys.removeFromRoute.tr()
                                    : LocaleKeys.addToRoute.tr(),
                                onPressed: () async {
                                  if (updatedBranch.stop != null) {
                                    // Unassign
                                    final success = await branchContr
                                        .unAssignMyRoute(
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
                                    DateTime? initialDate;
                                    try {
                                      if (branch.stop?.timeSlot != null &&
                                          branch.stop!.timeSlot.isNotEmpty) {
                                        initialDate = DateTime.parse(
                                          branch.stop!.timeSlot,
                                        );
                                      }
                                    } catch (_) {
                                      initialDate = DateTime.now();
                                    }

                                    final String? pickedDate =
                                        await pickRouteDate(
                                          context,
                                          currentTimeSlot:
                                              branch.stop?.timeSlot,
                                          initialDate: initialDate,
                                          maxDaysAhead: 7,
                                        );

                                    if (pickedDate != null) {
                                      final success = await branchContr
                                          .assignRouteToMe(
                                            branchId: branch.id,
                                            branchName: branch.name,
                                            timeSlot: pickedDate,
                                            context: context,
                                            branchTemplateId: branch.templateId,
                                            branchAddress: branch.address,
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
                                backgroundColor: updatedBranch.stop != null
                                    ? AppColors.primaryRed
                                    : AppColors.amber,
                                textStyle: TextStyle(
                                  fontSize: 11,
                                  color: updatedBranch.stop != null
                                      ? Colors.white
                                      : AppColors.primaryDark,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                borderRadius: 10,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (branch.stop != null &&
                            branch.isNextInspectionToday &&
                            branch.stop?.timeSlot != null)
                          Expanded(
                            child: AppButton(
                              text: LocaleKeys.submit_inspection.tr(),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ScreenSubmitReport(
                                      selectedBranch: branch,
                                      branchId: branch.id,
                                      branchTemplateId: branch.templateId,
                                    ),
                                  ),
                                );
                              },
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
      },
    );
  }
}
