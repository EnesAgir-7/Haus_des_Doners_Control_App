import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/inspection_template_model.dart';
import '../../inspector/widgets/app_button.dart';
import '../admin_firebase_services/admin_template_service.dart';

class ScreenAdminTemplates extends StatefulWidget {
  const ScreenAdminTemplates({super.key});

  @override
  State<ScreenAdminTemplates> createState() => _ScreenAdminTemplatesState();
}

class _ScreenAdminTemplatesState extends State<ScreenAdminTemplates> {
  final TemplateHelper _templateHelper = TemplateHelper();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "addTemplateFab",
        onPressed: () => _showCreateTemplateDialog(),
        backgroundColor: AppColors.primaryRed,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Template',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 12),
                Expanded(child: _buildTemplatesList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.description, color: Colors.lightBlueAccent),
        SizedBox(width: 6),
        Text(
          'Inspection Templates',
          style: TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search templates...',
        hintStyle: TextStyle(color: Colors.white54),
        prefixIcon: Icon(Icons.search, color: Colors.white54),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: Colors.white54),
                onPressed: () => setState(() => _searchQuery = ''),
              )
            : null,
        filled: true,
        fillColor: AppColors.lightBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryRed),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildTemplatesList() {
    return StreamBuilder<List<InspectionTemplate>>(
      stream: _templateHelper.templatesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final templates = snapshot.data ?? [];
        final filteredTemplates = templates.where((template) {
          return template.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
        }).toList();

        if (filteredTemplates.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: 80),
          itemCount: filteredTemplates.length,
          itemBuilder: (context, index) {
            final template = filteredTemplates[index];
            return _buildTemplateCard(template);
          },
        );
      },
    );
  }

  Widget _buildTemplateCard(InspectionTemplate template) {
    return GestureDetector(
      onTap: () => _showTemplateDetails(template),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${template.categories.length} Categories',
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: template.categories.map((category) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryRed),
                  ),
                  child: Text(
                    category.title,
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: AppColors.primaryRed),
          SizedBox(height: 16),
          Text(
            'Error Loading Templates',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 80, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No templates created yet'
                : 'No templates found',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _searchQuery = ''),
              child: Text(
                'Clear search',
                style: TextStyle(color: AppColors.primaryRed),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCreateTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => TemplateFormDialog(templateHelper: _templateHelper),
    );
  }

  void _showTemplateDetails(InspectionTemplate template) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.lightBlack,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TemplateDetailsSheet(
        template: template,
        templateHelper: _templateHelper,
      ),
    );
  }
}

// Template Form Dialog for Create/Edit
class TemplateFormDialog extends StatefulWidget {
  final TemplateHelper templateHelper;
  final InspectionTemplate? template;

  const TemplateFormDialog({required this.templateHelper, this.template});

  @override
  State<TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends State<TemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<CategoryInput> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _categories.addAll(
        widget.template!.categories.map(
          (cat) => CategoryInput(
            titleController: TextEditingController(text: cat.title),
            maxScore: cat.maxScore,
            categoryId: cat.categoryId,
          ),
        ),
      );
    } else {
      _addCategory();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var cat in _categories) {
      cat.titleController.dispose();
    }
    super.dispose();
  }

  void _addCategory() {
    setState(() {
      _categories.add(
        CategoryInput(
          titleController: TextEditingController(),
          maxScore: 4,
          categoryId: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
    });
  }

  void _removeCategory(int index) {
    setState(() {
      _categories[index].titleController.dispose();
      _categories.removeAt(index);
    });
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('At least one category is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final categories = _categories.map((cat) {
      return InspectionCategory(
        categoryId: cat.categoryId,
        title: cat.titleController.text.trim(),
        maxScore: cat.maxScore,
      );
    }).toList();

    bool success;
    if (widget.template != null) {
      success = await widget.templateHelper.updateTemplate(
        templateId: widget.template!.id,
        name: _nameController.text,
        categories: categories,
        context: context,
      );
    } else {
      final id = await widget.templateHelper.createTemplate(
        name: _nameController.text,
        categories: categories,
        context: context,
      );
      success = id != null;
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.lightBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: AppColors.primaryRed),
                  SizedBox(width: 8),
                  Text(
                    widget.template != null
                        ? 'Edit Template'
                        : 'Create Template',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Template Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.primaryDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryRed),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Template name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Categories',
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.green),
                    onPressed: _addCategory,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryInput(index);
                  },
                ),
              ),
              SizedBox(height: 16),
              AppButton(
                isLoading: _isLoading,
                text: widget.template != null
                    ? 'Update Template'
                    : 'Create Template',
                onPressed: _saveTemplate,
                backgroundColor: AppColors.primaryRed,
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                borderRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryInput(int index) {
    final category = _categories[index];
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: category.titleController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Category ${index + 1}',
                    labelStyle: TextStyle(color: Colors.white54, fontSize: 12),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: AppColors.lightBlack,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 8),
              if (_categories.length > 1)
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _removeCategory(index),
                ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Max Score: ',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  value: category.maxScore.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: AppColors.primaryRed,
                  label: category.maxScore.toString(),
                  onChanged: (value) {
                    setState(() {
                      category.maxScore = value.toInt();
                    });
                  },
                ),
              ),
              Text(
                '${category.maxScore}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryInput {
  final TextEditingController titleController;
  int maxScore;
  final String categoryId;

  CategoryInput({
    required this.titleController,
    required this.maxScore,
    required this.categoryId,
  });
}

// Template Details Bottom Sheet
class TemplateDetailsSheet extends StatelessWidget {
  final InspectionTemplate template;
  final TemplateHelper templateHelper;

  const TemplateDetailsSheet({
    required this.template,
    required this.templateHelper,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDragHandle(),
              SizedBox(height: 12),
              _buildHeader(context),
              SizedBox(height: 16),
              Divider(color: Colors.white24),
              SizedBox(height: 12),
              Text(
                'Categories (${template.categories.length})',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: template.categories.length,
                  itemBuilder: (context, index) {
                    final category = template.categories[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightRed,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              category.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 12, color: Colors.amber),
                                SizedBox(width: 4),
                                Text(
                                  'Max: ${category.maxScore}',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              _buildActionButtons(context),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Template ID: ${template.id}',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Edit',
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => TemplateFormDialog(
                  templateHelper: templateHelper,
                  template: template,
                ),
              );
            },
            backgroundColor: AppColors.amber,
            textStyle: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            borderRadius: 10,
          ),
        ),
        SizedBox(width: 12),
        // ADD THE DELETE BUTTON AND LOGIC HERE
        Expanded(
          child: AppButton(
            text: 'Delete',
            onPressed: () => _showDeleteConfirmationDialog(context),
            backgroundColor: AppColors.primaryDark,

            padding: const EdgeInsets.symmetric(vertical: 14),
            borderRadius: 10,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        title: Text(
          'Confirm Deletion',
          style: TextStyle(color: AppColors.primaryRed),
        ),
        content: Text(
          'Are you sure you want to delete the template "${template.name}"? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Close bottom sheet
              await templateHelper.deleteTemplate(
                templateId: template.id,
                context: context,
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
