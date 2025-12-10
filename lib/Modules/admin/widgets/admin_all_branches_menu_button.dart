import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';

import '../../../core/constants/firebase_constants.dart';

class BranchActionsMenuButton extends StatelessWidget {
  final VoidCallback onCreateAnnouncement;
  final VoidCallback onUpdateRequests;
  final VoidCallback onTrainingVideos;

  const BranchActionsMenuButton({
    Key? key,
    required this.onCreateAnnouncement,
    required this.onUpdateRequests,
    required this.onTrainingVideos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: FutureBuilder<int>(
        future: FirebaseFirestore.instance
            .collection(Collections.updateRequests)
            .where('status', isEqualTo: 'pending')
            .count()
            .get()
            .then((agg) => agg.count ?? 0),
        builder: (context, snap) {
          final pending = snap.hasData ? snap.data! : 0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (pending > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.lightBlack,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      offset: const Offset(0, 50),

      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'announcement',
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: Colors.teal,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Announcement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'training_videos',
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.video_library_outlined,
                    color: AppColors.primaryRed,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Training Videos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Divider
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 1,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),

        // Lightweight requests item using aggregation count() (returns only count, no full docs)
        PopupMenuItem<String>(
          value: 'requests',
          padding: EdgeInsets.zero,
          child: FutureBuilder<int>(
            future: FirebaseFirestore.instance
                .collection(Collections.updateRequests)
                .where('status', isEqualTo: 'pending')
                .count()
                .get()
                .then((agg) => agg.count ?? 0),
            builder: (context, snap) {
              final pending = snap.data ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.update_outlined,
                        color: Colors.orange,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Update Requests',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (pending > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pending > 99 ? '99+' : pending.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],

      onSelected: (value) {
        switch (value) {
          case 'announcement':
            onCreateAnnouncement();
            break;
          case 'requests':
            onUpdateRequests();
            break;
          case 'training_videos':
            onTrainingVideos();
            break;
        }
      },
      menuPadding: EdgeInsets.zero,
      padding: EdgeInsets.zero,
    );
  }
}
