import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/admin/screens/screen_admin_branch_details.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';

import '../../../models/branch_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/custom_app_bar.dart';
import '../admin_firebase_services/admin_branch_service.dart';

class ScreenAdminInspectorBranches extends StatefulWidget {
  final List<String> branchIds;
  final String inspectorName;

  const ScreenAdminInspectorBranches({
    super.key,
    required this.branchIds,
    required this.inspectorName,
  });

  @override
  State<ScreenAdminInspectorBranches> createState() =>
      _ScreenAdminInspectorBranchesState();
}

class _ScreenAdminInspectorBranchesState
    extends State<ScreenAdminInspectorBranches> {
  final AdminBranchService _branchService = AdminBranchService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<BranchModel> _allBranches = []; // store all branches locally
  List<BranchModel> _filteredBranches = [];

  Stream<List<BranchModel>>? _branchesStream;

  @override
  void initState() {
    super.initState();
    _branchesStream = _branchService.streamBranchesByIds(widget.branchIds);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filteredBranches = _filterBranches(_allBranches);
    });
  }

  List<BranchModel> _filterBranches(List<BranchModel> branches) {
    if (_searchQuery.isEmpty) return branches;

    return branches
        .where(
          (branch) =>
              branch.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "${widget.inspectorName} ${LocaleKeys.branches.tr()}",
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<BranchModel>>(
              stream: _branchesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('${LocaleKeys.error.tr()}: ${snapshot.error}'));
                }

                _allBranches = snapshot.data ?? [];
                _filteredBranches = _filterBranches(_allBranches);

                if (_allBranches.isEmpty) {
                  return  Center(child: Text(LocaleKeys.noBranchesAssigned.tr()));
                }

                if (_filteredBranches.isEmpty) {
                  return  Center(child: Text(LocaleKeys.noBranchesFound.tr()));
                }

                return ListView.separated(
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemCount: _filteredBranches.length,
                  itemBuilder: (context, index) {
                    final branch = _filteredBranches[index];
                    return _buildBranchCard(branch);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.white60, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                fillColor: Colors.transparent,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText:  LocaleKeys.searchBranches.tr(),
                hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              icon: Icon(Icons.close_rounded, color: Colors.white60, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(BranchModel branch) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScreenAdminBranchDetails(branch: branch),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                      ),
                      child: Icon(
                        Icons.store_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (branch.lastInspectionText.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                branch.lastInspectionText,
                                style: TextStyle(
                                  color: AppColors.primaryRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white38,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInfoRow(Icons.location_on_outlined, branch.address),
                if (branch.contactName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.person_outline_rounded,
                    branch.contactName,
                  ),
                ],
                if (branch.contactPhone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.phone_outlined, branch.contactPhone),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
