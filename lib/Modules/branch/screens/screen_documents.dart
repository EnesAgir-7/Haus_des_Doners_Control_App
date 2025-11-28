import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/custom_app_bar.dart';

class ScreenDocuments extends StatelessWidget {
  const ScreenDocuments({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    return Scaffold(
      appBar: CustomAppBar(title: LocaleKeys.documents.tr()),
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: 10,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDocumentItem(context, index),
                  ),
                  childCount: 8,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(BuildContext context, int index) {
    final documentNames = [
      'Branch Guidelines',
      'Safety Protocols',
      'Health Standards',
      'Employee Handbook',
      'Inspection Checklist',
      'Compliance Report',
      'Training Manual',
      'Certificate',
    ];

    final documentTypes = [
      'PDF',
      'PDF',
      'DOCX',
      'PDF',
      'PDF',
      'XLSX',
      'PDF',
      'PDF',
    ];
    final sizes = [
      '120 KB',
      '85 KB',
      '240 KB',
      '1.2 MB',
      '95 KB',
      '340 KB',
      '2.1 MB',
      '180 KB',
    ];
    final dates = ['2d', '5d', '1w', '2w', '3d', '1w', '4d', '6d'];

    final icons = [
      Icons.description,
      Icons.security,
      Icons.health_and_safety,
      Icons.people,
      Icons.checklist,
      Icons.assessment,
      Icons.menu_book,
      Icons.workspace_premium,
    ];

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.red,
      Colors.amber,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors[index].withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icons[index], color: colors[index], size: 20),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documentNames[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors[index].withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        documentTypes[index],
                        style: TextStyle(
                          color: colors[index],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sizes[index],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '•',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dates[index],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Download Button
          IconButton(
            onPressed: () {
              // Handle download
            },
            icon: const Icon(
              Icons.download_outlined,
              color: AppColors.primaryRed,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
