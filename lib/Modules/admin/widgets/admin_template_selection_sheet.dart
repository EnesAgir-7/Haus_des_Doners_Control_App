// lib/screens/admin/widgets/template_selection_sheet.dart (New File)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/inspection_template_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../admin_firebase_services/admin_template_service.dart';
import '../screens/screen_admin_templates.dart';

class TemplateSelectionSheet extends StatelessWidget {
  final TemplateHelper templateHelper;
  final bool showNote;
  final Function(InspectionTemplate template) onTemplateSelected;

  const TemplateSelectionSheet({
    required this.templateHelper,
    required this.onTemplateSelected,
    super.key, required this.showNote,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildDragHandle(),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.selectInspectionTemplate.tr(),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            if(showNote)  Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      LocaleKeys.templateUpdateNote.tr(),
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<InspectionTemplate>>(
                  stream: templateHelper.templatesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryRed,
                        ),
                      );
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              LocaleKeys.noTemplatesAvailable.tr(),
                              style: const TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ScreenAdminQuestionnaires(),
                                  ),
                                );
                              },
                              child: Text(
                                LocaleKeys.createQuestionnaire.tr(),
                                style: const TextStyle(color: AppColors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final templates = snapshot.data!;
                    return ListView.builder(
                      key: const PageStorageKey('templatesList'),
                      controller: scrollController,
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return _buildTemplateTile(context, template);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTemplateTile(BuildContext context, InspectionTemplate template) {
    return GestureDetector(
      onTap: () async {
        await onTemplateSelected(template);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gradient accent bar
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryRed,
                    AppColors.primaryRed.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.category,
                        size: 14,
                        color: AppColors.primaryRed,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${template.categories.length} ${LocaleKeys.categories.tr()}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
