import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/inspection_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/screens/screen_inspection_details.dart';
import '../admin_firebase_services/admin_inspection_service.dart';
import '../screens/screen_admin_inspections.dart';

class InspectionSection extends StatefulWidget {
  const InspectionSection({super.key});

  @override
  State<InspectionSection> createState() => _InspectionSectionState();
}

class _InspectionSectionState extends State<InspectionSection> {
  late final Stream<List<InspectionModel>> _inspectionStream;

  final AdminInspectionService adminInspectionService =
      AdminInspectionService();

  @override
  void initState() {
    super.initState();
    // ✅ Only created once, even if parent rebuilds
    _inspectionStream = adminInspectionService.recentInspectionsStream();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(16),
      // decoration: BoxDecoration(
      //   gradient: LinearGradient(
      //     colors: [
      //       AppColors.lightBlack,
      //       AppColors.lightBlack.withValues(alpha: 0.8),
      //     ],
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //   ),
      //   borderRadius: BorderRadius.circular(24),
      //   border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withValues(alpha: 0.3),
      //       blurRadius: 20,
      //       offset: const Offset(0, 10),
      //     ),
      //   ],
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleKeys.recentInspections.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScreenAdminInspections(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.2),
                    border: Border.all(
                      color: AppColors.primaryRed.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        color: AppColors.primaryRed,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        LocaleKeys.viewAll.tr(),
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ StreamBuilder uses cached stream, no re-subscribing
          StreamBuilder<List<InspectionModel>>(
            stream: _inspectionStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    LocaleKeys.failedToLoadInspections.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                );
              }

              final inspections = snapshot.data ?? [];

              if (inspections.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    LocaleKeys.noRecentInspections.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                );
              }

              return Column(
                children: inspections.map((inspection) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScreenInspectionDetails(
                          inspectionId: inspection.id,
                        ),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.lightBlack.withValues(alpha: 0.6),
                            AppColors.lightBlack.withValues(alpha: 0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryRed.withValues(alpha: 0.4),
                                  AppColors.primaryRed.withValues(alpha: 0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryRed.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.assignment_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inspection.branchName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      color: AppColors.primaryRed.withValues(
                                        alpha: 0.8,
                                      ),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${LocaleKeys.submitted_by.tr()}: ${inspection.inspectorName}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.75,
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy, hh:mm a',
                                      ).format(inspection.updatedAt),
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
