import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/branch_card.dart';
import '../widgets/assign_inspector_dialog.dart';
import '../../providers/provider_admin_branches.dart';
import '../../translations/locale_keys.g.dart';

class AdminBranchesScreen extends StatefulWidget {
  const AdminBranchesScreen({super.key});

  @override
  State<AdminBranchesScreen> createState() => _AdminBranchesScreenState();
}

class _AdminBranchesScreenState extends State<AdminBranchesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load branches and inspectors when screen opens
    Future.microtask(() {
      context.read<ProviderAdminBranches>().loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: LocaleKeys.search_branches.tr(),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              context.read<ProviderAdminBranches>().setSearchQuery(value);
            },
          ),
        ),
        Expanded(
          child: Consumer<ProviderAdminBranches>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${provider.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.loadData(),
                        child: Text(LocaleKeys.retry.tr()),
                      ),
                    ],
                  ),
                );
              }

              final branches = provider.branches;
              if (branches.isEmpty) {
                if (_searchController.text.isNotEmpty) {
                  return Center(child: Text(LocaleKeys.no_branches_found.tr()));
                }
                return Center(
                  child: Text(LocaleKeys.no_branches_available.tr()),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadData(),
                child: ListView.builder(
                  itemCount: branches.length,
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    return BranchCard(branch: branch);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
