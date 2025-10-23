// lib/screens/admin/widgets/template_selection_sheet.dart (New File)

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/inspection_template_model.dart';
import '../admin_firebase_services/admin_template_service.dart';

class TemplateSelectionSheet extends StatelessWidget {
  final TemplateHelper templateHelper;
  final Function(InspectionTemplate  template) onTemplateSelected;

  const TemplateSelectionSheet({
    required this.templateHelper,
    required this.onTemplateSelected,
    super.key,
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
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _buildDragHandle(),
              SizedBox(height: 16),
              Text(
                'Select Inspection Template',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<InspectionTemplate>>(
                  stream: templateHelper.templatesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryRed,
                        ),
                      );
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No templates available. Create one first.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    final templates = snapshot.data!;
                    return ListView.builder(
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
      onTap: () {
        onTemplateSelected(template);
        Navigator.pop(context); 
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 12, color: AppColors.primaryRed),
                SizedBox(width: 4),
                Text(
                  '${template.categories.length} Categories',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Spacer(),
                Text(
                  'ID: ${template.id.substring(0, 6)}...',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
