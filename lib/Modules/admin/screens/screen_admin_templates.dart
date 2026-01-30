import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/inspection_template_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/app_button.dart';
import '../../inspector/widgets/custom_toast.dart';
import '../admin_firebase_services/admin_template_service.dart';

class ScreenAdminQuestionnaires extends StatefulWidget {
  const ScreenAdminQuestionnaires({super.key});

  @override
  State<ScreenAdminQuestionnaires> createState() =>
      _ScreenAdminQuestionnairesState();
}

class _ScreenAdminQuestionnairesState extends State<ScreenAdminQuestionnaires> {
  final TemplateHelper _templateHelper = TemplateHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "addQuestionnaireFab",
        onPressed: () => _showCreateTemplateDialog(),
        backgroundColor: AppColors.primaryRed,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          LocaleKeys.createQuestionnaire.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
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
        const Icon(Icons.description, color: Colors.lightBlueAccent),
        const SizedBox(width: 6),
        Text(
          LocaleKeys.inspectionQuestionnaires.tr(),
          style: const TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesList() {
    return StreamBuilder<List<InspectionTemplate>>(
      stream: _templateHelper.templatesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final templates = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${template.categories.length} ${LocaleKeys.categories.tr()}',
                    style: const TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: template.categories.map((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryRed),
                  ),
                  child: Text(
                    category.title,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
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
          const Icon(
            Icons.error_outline,
            size: 60,
            color: AppColors.primaryRed,
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.errorLoadingQuestionnaires.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TemplateDetailsSheet(
        questionnaire: template,
        questionnaireHelper: _templateHelper,
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

class _TemplateFormDialogState extends State<TemplateFormDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categories = <CategoryInput>[];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // static const int _minScore = 3;
  // static const int _maxScore = 6;
  // static const int _scoreSteps = 3;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _initializeForm();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _initializeForm() {
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

  void _disposeControllers() {
    _nameController.dispose();
    for (final cat in _categories) {
      cat.titleController.dispose();
    }
  }

  void _addCategory() {
    setState(() {
      _categories.add(
        CategoryInput(
          titleController: TextEditingController(),
          maxScore: 5,
          categoryId: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
    });
  }

  void _removeCategory(int index) {
    if (_categories.length <= 1) return;

    setState(() {
      _categories[index].titleController.dispose();
      _categories.removeAt(index);
    });
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate() || _categories.isEmpty) {
      if (_categories.isEmpty) {
        showSnakBarr(context, LocaleKeys.atLeastOneCategoryRequired.tr());
      }
      return;
    }

    setState(() => _isLoading = true);

    final categories = _categories
        .map(
          (cat) => InspectionCategory(
            categoryId: cat.categoryId,
            title: cat.titleController.text.trim(),
            maxScore: cat.maxScore,
          ),
        )
        .toList();

    final success = widget.template != null
        ? await widget.templateHelper.updateQuestionnaire(
            templateId: widget.template!.id,
            name: _nameController.text.trim(),
            categories: categories,
            context: context,
          )
        : await widget.templateHelper.createQuestionnaire(
                name: _nameController.text.trim(),
                categories: categories,
                context: context,
              ) !=
              null;

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          constraints: const BoxConstraints(),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.lightBlack],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildNameField(),
                const SizedBox(height: 24),
                _buildCategoriesHeader(),
                const SizedBox(height: 12),
                _buildCategoriesList(),
                const SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryRed,
                  AppColors.primaryRed.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.description, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.template != null
                      ? LocaleKeys.editQuestionnaire.tr()
                      : LocaleKeys.createQuestionnaire.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.template != null
                      ? LocaleKeys.updateTemplateDetails.tr()
                      : LocaleKeys.buildNewTemplate.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _nameController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: LocaleKeys.questionnaireName.tr(),
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: const Icon(Icons.edit_note, color: AppColors.primaryRed),
          filled: true,
          fillColor: AppColors.primaryDark.withValues(alpha: 0.5),
          border: _buildBorder(),
          enabledBorder: _buildBorder(),
          focusedBorder: _buildBorder(focused: true),
          errorBorder: _buildBorder(error: true),
          focusedErrorBorder: _buildBorder(error: true, focused: true),
        ),
        validator: (value) => value?.trim().isEmpty ?? true
            ? LocaleKeys.questionnaireNameRequired.tr()
            : null,
      ),
    );
  }

  OutlineInputBorder _buildBorder({bool focused = false, bool error = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: error
            ? Colors.red
            : focused
            ? AppColors.primaryRed
            : Colors.white.withValues(alpha: 0.2),
        width: focused ? 2 : 1.5,
      ),
    );
  }

  Widget _buildCategoriesHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryRed.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.category,
                  color: AppColors.primaryRed,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  LocaleKeys.categories.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_categories.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF00E676)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C853).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _addCategory,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        LocaleKeys.add.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4),
        itemCount: _categories.length,
        itemBuilder: (context, index) => _buildCategoryCard(index),
      ),
    );
  }

  Widget _buildCategoryCard(int index) {
    final category = _categories[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark.withValues(alpha: 0.8),
            AppColors.lightBlack.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCategoryTitleRow(index, category),
              // const SizedBox(height: 16),
              // _buildMaxScoreSlider(category),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTitleRow(int index, CategoryInput category) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: category.titleController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: LocaleKeys.enterCategoryName.tr(),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: _buildCategoryBorder(),
              enabledBorder: _buildCategoryBorder(),
              focusedBorder: _buildCategoryBorder(focused: true),
              errorBorder: _buildCategoryBorder(error: true),
            ),
            validator: (value) =>
                value?.trim().isEmpty ?? true ? LocaleKeys.required.tr() : null,
          ),
        ),
        if (_categories.length > 1) ...[
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => _removeCategory(index),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _buildCategoryBorder({
    bool focused = false,
    bool error = false,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: error
            ? Colors.red
            : focused
            ? AppColors.primaryRed
            : Colors.white.withValues(alpha: 0.2),
        width: focused ? 2 : 1,
      ),
    );
  }

  // Widget _buildMaxScoreSlider(CategoryInput category) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: Colors.white.withValues(alpha: 0.05),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //           decoration: BoxDecoration(
  //             color: AppColors.primaryRed.withValues(alpha: 0.2),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: const Text(
  //             'Max Score',
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontSize: 12,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: SliderTheme(
  //             data: SliderThemeData(
  //               activeTrackColor: AppColors.primaryRed,
  //               inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
  //               thumbColor: Colors.white,
  //               overlayColor: AppColors.primaryRed.withValues(alpha: 0.2),
  //               thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
  //               trackHeight: 6,
  //             ),
  //             child: Slider(
  //               value: category.maxScore.toDouble(),
  //               min: _minScore.toDouble(),
  //               max: _maxScore.toDouble(),
  //               divisions: _scoreSteps,
  //               label: category.maxScore.toString(),
  //               onChanged: (value) {
  //                 setState(() => category.maxScore = value.toInt());
  //               },
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 8),
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [
  //                 AppColors.primaryRed,
  //                 AppColors.primaryRed.withValues(alpha: 0.8),
  //               ],
  //             ),
  //             borderRadius: BorderRadius.circular(8),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: AppColors.primaryRed.withValues(alpha: 0.3),
  //                 blurRadius: 4,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           child: Text(
  //             '${category.maxScore}',
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontWeight: FontWeight.bold,
  //               fontSize: 16,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSubmitButton() {
    return AppButton(
      isLoading: _isLoading,
      text: widget.template != null
          ? LocaleKeys.updateQuestionnaire.tr()
          : LocaleKeys.createQuestionnaire.tr(),
      onPressed: _saveTemplate,
      padding: const EdgeInsets.symmetric(vertical: 16),
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
  final InspectionTemplate questionnaire;
  final TemplateHelper questionnaireHelper;

  const TemplateDetailsSheet({
    required this.questionnaire,
    required this.questionnaireHelper,
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDragHandle(),
              const SizedBox(height: 12),
              _buildHeader(context),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              Text(
                '${LocaleKeys.categories.tr()} (${questionnaire.categories.length})',
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: questionnaire.categories.length,
                  itemBuilder: (context, index) {
                    final category = questionnaire.categories[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
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
                            decoration: const BoxDecoration(
                              color: AppColors.primaryRed,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              category.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
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
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${LocaleKeys.max.tr()}: ${category.maxScore}',
                                  style: const TextStyle(
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
              const SizedBox(height: 16),
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
                questionnaire.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${LocaleKeys.questionnaireId.tr()}: ${questionnaire.id}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
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
            text: LocaleKeys.edit.tr(),
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => TemplateFormDialog(
                  templateHelper: questionnaireHelper,
                  template: questionnaire,
                ),
              );
            },
            backgroundColor: AppColors.amber,
            textStyle: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            borderRadius: 10,
          ),
        ),
        const SizedBox(width: 12),
        // ADD THE DELETE BUTTON AND LOGIC HERE
        Expanded(
          child: AppButton(
            text: LocaleKeys.delete.tr(),
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
          LocaleKeys.confirmDeletion.tr(),
          style: const TextStyle(color: AppColors.primaryRed),
        ),
        content: Text(
          LocaleKeys.deleteQuestionnaireConfirm.tr().replaceAll(
            '{questionnaireName}',
            questionnaire.name,
          ),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              LocaleKeys.cancel.tr(),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Close bottom sheet
              await questionnaireHelper.deleteTemplate(
                templateId: questionnaire.id,
                context: context,
              );
            },
            child: Text(
              LocaleKeys.delete.tr(),
              style: const TextStyle(
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
