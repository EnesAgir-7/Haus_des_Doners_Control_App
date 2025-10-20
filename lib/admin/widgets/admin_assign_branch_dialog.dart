import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_colors.dart';
import '../../models/branch_model.dart';
import '../../models/user_model.dart';
import '../admin_providers/provider_admin_users.dart';
import '../../translations/locale_keys.g.dart';
import 'package:provider/provider.dart';

class AssignBranchDialog extends StatefulWidget {
  final UserModel user;
  final List<BranchModel> assignedBranches;

  const AssignBranchDialog({
    super.key,
    required this.user,
    required this.assignedBranches,
  });

  @override
  State<AssignBranchDialog> createState() => _AssignBranchDialogState();
}

class _AssignBranchDialogState extends State<AssignBranchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<BranchModel>? _availableBranches;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableBranches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableBranches() async {
    final provider = context.read<ProviderAdminUsers>();
    setState(() => _isLoading = true);
    try {
      final branches = await provider.getUnassignedBranches();
      setState(() {
        _availableBranches = branches;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  List<BranchModel> get filteredBranches {
    if (_availableBranches == null) return [];
    if (_searchQuery.isEmpty) return _availableBranches!;

    return _availableBranches!.where((branch) {
      final name = branch.name.toLowerCase();
      final address = branch.address.toLowerCase();
      final region = (branch.region ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) ||
          address.contains(query) ||
          region.contains(query);
    }).toList();
  }

  Future<void> _assignBranch(BranchModel branch) async {
    final provider = context.read<ProviderAdminUsers>();
    try {
      await provider.assignBranchToUser(widget.user.id, branch.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleKeys.branch_assigned_successfully.tr())),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.lightBlack,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocaleKeys.assign_branch.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: LocaleKeys.search_branches.tr(),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryRed),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_availableBranches?.isEmpty ?? true)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(LocaleKeys.no_branches_available.tr()),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredBranches.length,
                  itemBuilder: (context, index) {
                    final branch = filteredBranches[index];
                    return Card(
                      color: AppColors.greyCardColor,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(branch.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(branch.address),
                            if (branch.region != null)
                              Text(
                                branch.region!,
                                style: TextStyle(color: AppColors.primaryRed),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppColors.primaryRed,
                          onPressed: () => _assignBranch(branch),
                        ),
                        isThreeLine: branch.region != null,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
