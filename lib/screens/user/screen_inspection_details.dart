// lib/screens/screen_inspection_details.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/screens/user/screen_full_image.dart';
import 'package:haus_des_control/widgets/app_button.dart';
import 'package:haus_des_control/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../generated/lib/translations/locale_keys.g.dart';
import '../../helpers/app_helpers.dart';
import '../../models/inspection_model.dart';
import '../../providers/provider_inspections.dart';

class ScreenInspectionDetails extends StatefulWidget {
  final String inspectionId;

  const ScreenInspectionDetails({super.key, required this.inspectionId});

  @override
  State<ScreenInspectionDetails> createState() =>
      _ScreenInspectionDetailsState();
}

class _ScreenInspectionDetailsState extends State<ScreenInspectionDetails> {
  String path = "";
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((v) {
      context.read<ProviderInspection>().fetchInspectionDetails(
        widget.inspectionId,
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(showLogout: false, showLang: false),

      // AppBar(
      //   title: Text(
      //     LocaleKeys.inspection_details.tr(),
      //     style: const TextStyle(color: Colors.white),
      //   ),
      //   backgroundColor: AppColors.primaryDark,
      //   iconTheme: const IconThemeData(color: Colors.white),
      // ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryRed.withValues(alpha: 0.08),
              AppColors.primaryDark,
              AppColors.primaryDark,
            ],
            stops: const [0.0, 0.25, 1.0],
          ),
        ),
        child: Consumer<ProviderInspection>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              );
            }

            if (provider.errorMessage != null) {
              return _buildErrorState(provider.errorMessage!);
            }

            if (provider.inspection == null) {
              return _buildErrorState("Inspection Not found");
            }

            return _buildDetailsBody(context, provider, provider.inspection!);
          },
        ),
      ),
    );
  }

  Widget _buildDetailsBody(
    BuildContext context,
    ProviderInspection provider,
    InspectionModel inspection,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(provider, inspection),
          const SizedBox(height: 16),
          _buildInspectionInfo(inspection),
          const Divider(color: Colors.white24, height: 32),
          _buildOverallNotes(inspection),
          const Divider(color: Colors.white24, height: 32),
          _buildCategories(context, provider, inspection),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    ProviderInspection provider,
    InspectionModel inspection,
  ) {
    final scoreColor = provider.getScoreColor(inspection.score);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  inspection.branchName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scoreColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 18, color: scoreColor),
                    const SizedBox(width: 4),
                    Text(
                      inspection.score.toStringAsFixed(1),
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${LocaleKeys.status.tr()}: ${inspection.status.toUpperCase()}',
            style: TextStyle(
              color: scoreColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionInfo(InspectionModel inspection) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            Icons.person_outline,
            LocaleKeys.inspector.tr(),
            inspection.inspectorName ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.calendar_today,
            "Scheduled",
            formatDate(inspection.scheduledTime),
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.done_all,
            "Completed On",
            inspection.completedTime != null
                ? formatDate(inspection.completedTime!)
                : LocaleKeys.in_progress.tr(),
          ),
          if (inspection.publicUrl != null && inspection.publicUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AppButton(
                text: "View pdf report",
                onPressed: () => openInBrowser(inspection.publicUrl!, context),
                icon: Icons.picture_as_pdf,
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryRed),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildOverallNotes(InspectionModel inspection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.overall_notes.tr(),
          style: TextStyle(
            color: AppColors.primaryRed,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            inspection.overallNotes.isNotEmpty
                ? inspection.overallNotes
                : "No Overall notes",
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories(
    BuildContext context,
    ProviderInspection provider,
    InspectionModel inspection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Category break down",
          style: TextStyle(
            color: AppColors.primaryRed,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...inspection.categories.entries.map((entry) {
          final categoryName = entry.key.replaceAll(
            '_',
            ' ',
          ); // Simple title formatting
          final categoryData = entry.value;

          return _buildCategoryCard(
            context,
            provider,
            categoryName,
            categoryData,
            path,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    ProviderInspection provider,
    String title,
    InspectionCategoryModel data,
    String path,
  ) {
    final scoreColor = provider.getScoreColor(data.score.toDouble());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: scoreColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 12, color: scoreColor),
                      const SizedBox(width: 4),
                      Text(
                        '${data.score}/4',
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 20),

            // Notes
            Text(
              "Notes",
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.notes.isNotEmpty ? data.notes : "No Note Provided",
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),

            // Photos
            if (data.photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                "Photoes",
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.photos.length,
                  itemBuilder: (ctx, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == data.photos.length - 1 ? 0 : 8,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenImageViewer(
                                  images: data.photos,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: CachedNetworkImage(
                            imageUrl: data.photos[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade800,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: AppColors.primaryRed),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.error_occurred.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Note: Refresh action not included here since the ID is passed
            // The screen will refresh if rebuilt, or the user can pop and push again.
          ],
        ),
      ),
    );
  }
}
