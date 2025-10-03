import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:haus_des_control/providers/provider_branches.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/dummy_branches.dart';
import '../../models/branch_model.dart';
import '../../providers/provider_map.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_app_bar.dart';

class BranchMapScreen extends StatelessWidget {
  const BranchMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BranchMapController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: CustomAppBar(showLogout: false, showLang: false),
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    dummyBranches[0].gps.latitude,
                    dummyBranches[0].gps.longitude,
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
                  itemCount: dummyBranches.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: controller.onPageChanged,
                  itemBuilder: (context, index) {
                    final branch = dummyBranches[index];
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
                  // Image.network(
                  //   branch.imageUrl ?? '',
                  //   width: 60,
                  //   height: 60,
                  //   fit: BoxFit.cover,
                  //   errorBuilder: (_, __, ___) =>
                  //       Icon(Icons.apartment, size: 50, color: Colors.white24),
                  // ),
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
                  spacing: 10,
                  children: [
                    Expanded(
                      child: Consumer<ProviderBranches>(
                        builder: (context, branchContr, child) {
                          return AppButton(
                            isLoading: branchContr.isLoading,
                            text: "Assign to Me",
                            onPressed: () {
                              branchContr.assignBranchTome(
                                branchId: branch.id,
                                branchName: branch.name,
                                timeSlot: "9 to 5",
                                context: context,
                              );
                            },
                            backgroundColor: AppColors.amber,
                            textStyle: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryDark,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            borderRadius: 10,
                          );
                        },
                      ),
                    ),
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
