import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../admin_providers/provider_admin_users.dart';
import '../../../translations/locale_keys.g.dart';
import 'screen_admin_user_details.dart';
import 'screen_admin_create_user.dart';

class ScreenAdminUsers extends StatefulWidget {
  const ScreenAdminUsers({super.key});

  @override
  State<ScreenAdminUsers> createState() => _ScreenAdminUsersState();
}

class _ScreenAdminUsersState extends State<ScreenAdminUsers> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderAdminUsers>().streamAllInspectors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Apply the same gradient background as ScreenBranches
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildSearchBar(context),
              const SizedBox(height: 12),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 12),
              Expanded(
                child: Consumer<ProviderAdminUsers>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryRed,
                        ),
                      );
                    }

                    if (provider.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              LocaleKeys.error_occurred.tr(),
                              style: TextStyle(
                                color: AppColors.primaryRed,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error: ${provider.error}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => provider.streamAllInspectors(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                              ),
                              child: Text(LocaleKeys.retry.tr()),
                            ),
                          ],
                        ),
                      );
                    }

                    final inspectors = provider.inspectors;
                    if (inspectors.isEmpty) {
                      final text = _searchController.text.isNotEmpty
                          ? LocaleKeys.no_users_found.tr()
                          : 'No users available';
                      return Center(
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: inspectors.length,
                      itemBuilder: (context, index) {
                        final inspector = inspectors[index];
                        return _InspectorListItem(inspector: inspector);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.people, color: Colors.lightBlueAccent),
        const SizedBox(width: 6),
        Text(
          'Inspectors',
          style: TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const Spacer(),
        // Create User Button
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScreenAdminCreateUser(),
              ),
            );
          },
          icon: const Icon(Icons.add, size: 20),
          label: Text(LocaleKeys.create_user.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final provider = context.read<ProviderAdminUsers>();
    return TextField(
      controller: _searchController,
      onChanged: (value) => provider.setSearchQuery(value),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: LocaleKeys.search.tr(),
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.lightBlack, // Use lightBlack for the fill color
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryRed,
          ), // PrimaryRed focus color
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
    );
  }
}

// ---
// The _InspectorListItem has been refactored to use the BranchCard style
// ---

class _InspectorListItem extends StatelessWidget {
  final UserModel inspector;

  const _InspectorListItem({required this.inspector});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenAdminUserDetails(inspector: inspector),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightBlack, // Darker background for card
          borderRadius: BorderRadius.circular(12),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading Circle Avatar
            CircleAvatar(
              backgroundColor: AppColors.primaryRed,
              child: Text(
                inspector.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // User Details (Title/Subtitle)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inspector.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    inspector.email,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${LocaleKeys.role.tr()}: ',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        inspector.role.toUpperCase(),
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (inspector.region != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${LocaleKeys.region.tr()}: ${inspector.region}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Trailing Switch for Active Status
            Switch(
              value: inspector.active,
              onChanged: (value) async {
                await context.read<ProviderAdminUsers>().toggleInspectorActive(
                  inspector.id,
                  value,
                );
              },
              activeThumbColor: Colors.greenAccent,
              inactiveThumbColor: Colors.redAccent,
              inactiveTrackColor: Colors.redAccent.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// Ensure you have AppColors, UserModel, ProviderAdminUsers, and translation keys imported correctly.
