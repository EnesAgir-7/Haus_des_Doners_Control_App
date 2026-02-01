import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/branch/branch_providers/provider_branch_dashboard.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/announcement_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/custom_app_bar.dart';
import '../admin_providers/provider_admin_announcements.dart';

class ScreenAnnouncementDetails extends StatefulWidget {
  final AnnouncementModel announcement;
  final String role; // 'admin' or 'branch'

  const ScreenAnnouncementDetails({
    super.key,
    required this.announcement,
    required this.role,
  });

  @override
  State<ScreenAnnouncementDetails> createState() =>
      _ScreenAnnouncementDetailsState();
}

class _ScreenAnnouncementDetailsState extends State<ScreenAnnouncementDetails> {
  @override
  void initState() {
    super.initState();
    _markAsSeenIfNeeded();
  }

  void _markAsSeenIfNeeded() {
    if (widget.role.toLowerCase() == AppConstants.branch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        String? bId;
        String? bName;

        // Use loggedInUser directly (most reliable)
        if (loggedInUser != null && loggedInUser!.id.isNotEmpty) {
          bId = loggedInUser!.id;
          bName = loggedInUser!.name;
        } else {
          // Fallback to provider if loggedInUser is not synced yet
          final branchProvider = context.read<ProviderBranchDashboard>();
          bId = branchProvider.branchInfo?.id;
          bName = branchProvider.branchInfo?.name;
        }

        if (bId != null &&
            bId.isNotEmpty &&
            bName != null &&
            bName.isNotEmpty) {
          context.read<AdminAnnouncementsProvider>().markAnnouncementAsSeen(
            announcementId: widget.announcement.id,
            branchId: bId,
            branchName: bName,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    final isAdmin = widget.role.toLowerCase() == AppConstants.admin;

    return Scaffold(
      appBar: CustomAppBar(title: LocaleKeys.announcement_details.tr()),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.lightBlack,
                        AppColors.lightBlack.withValues(alpha: 0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.campaign,
                              color: AppColors.primaryRed,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.announcement.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        height: 1,
                      ),
                      const SizedBox(height: 16),
                      // Date and Author Info
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.announcement.createdAt != null
                                ? DateFormat(
                                    'MMMM dd, yyyy - hh:mm a',
                                  ).format(widget.announcement.createdAt!)
                                : LocaleKeys.na.tr(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${LocaleKeys.created_by.tr()} ${widget.announcement.createdBy}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Seen By Section (ADMIN ONLY)
                if (isAdmin) ...[
                  _buildSeenBySection(isTablet),
                  const SizedBox(height: 20),
                ],

                // Description Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            LocaleKeys.description.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.announcement.description.isNotEmpty
                            ? widget.announcement.description
                            : LocaleKeys.no_description_provided.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // Admin Delete Button at bottom
                if (isAdmin) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDeleteConfirmation(context),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(LocaleKeys.delete_announcement.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeenBySection(bool isTablet) {
    return Consumer<AdminAnnouncementsProvider>(
      builder: (context, provider, child) {
        final latestAnnouncement = provider.announcements.firstWhere(
          (a) => a.id == widget.announcement.id,
          orElse: () => widget.announcement,
        );

        final seenCount = latestAnnouncement.seenBy.length;

        return InkWell(
          onTap: seenCount > 0
              ? () => _showSeenByBottomSheet(latestAnnouncement.seenBy)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.visibility_outlined,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.seen_by_branches.tr(
                          namedArgs: {'count': seenCount.toString()},
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (seenCount > 0)
                        Text(
                          LocaleKeys.tap_to_see_viewed.tr(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (seenCount > 0)
                  const Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: Colors.white70,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSeenByBottomSheet(List<AnnouncementSeenInfo> seenBy) {
    final searchNotifier = ValueNotifier<String>("");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.viewed_by.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (val) => searchNotifier.value = val,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: LocaleKeys.search_branch_placeholder.tr(),
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: searchNotifier,
                  builder: (context, query, _) {
                    final filteredList = seenBy
                        .where(
                          (e) => e.branchName.toLowerCase().contains(
                            query.toLowerCase(),
                          ),
                        )
                        .toList();

                    if (filteredList.isEmpty) {
                      return ListView(
                        controller: scrollController,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  LocaleKeys.no_branches_found_search.tr(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      itemCount: filteredList.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withValues(alpha: 0.05),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final info = filteredList[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryRed.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              info.branchName.isNotEmpty
                                  ? info.branchName[0].toUpperCase()
                                  : 'B',
                              style: const TextStyle(
                                color: AppColors.primaryRed,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            info.branchName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('MMM dd, hh:mm a').format(info.seenAt),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => searchNotifier.dispose());
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.lightBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
              const SizedBox(width: 12),
              Text(
                LocaleKeys.delete_announcement.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            LocaleKeys.delete_confirmation.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                LocaleKeys.cancel.tr(),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteAnnouncement(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(LocaleKeys.delete.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAnnouncement(BuildContext context) async {
    final provider = Provider.of<AdminAnnouncementsProvider>(
      context,
      listen: false,
    );

    final success = await provider.deleteAnnouncement(
      widget.announcement.id,
      context: context,
    );

    if (success && context.mounted) {
      Navigator.of(context).pop(); // Go back to announcements list
    }
  }
}
