import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../admin_providers/provider_admin_users.dart';
import 'screen_admin_create_user.dart';
import 'screen_admin_inspector_details.dart';

class ScreenAdminInspectors extends StatefulWidget {
  const ScreenAdminInspectors({super.key});

  @override
  State<ScreenAdminInspectors> createState() => _ScreenAdminInspectorsState();
}

class _ScreenAdminInspectorsState extends State<ScreenAdminInspectors> {
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
    return PopScope(
      canPop: false,
      child: Scaffold(
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
            child: Consumer<ProviderAdminUsers>(
              builder: (context, provider, child) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(provider),
                      const SizedBox(height: 12),
                      _buildSearchBar(provider),
                      const SizedBox(height: 12),
                      Container(height: 1, color: Colors.white24),
                      const SizedBox(height: 12),
                      Expanded(child: _buildUsersList(provider)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        floatingActionButton: _buildFAB(context),
      ),
    );
  }

  Widget _buildHeader(ProviderAdminUsers provider) {
    return Row(
      children: [
        Icon(Icons.people, color: Colors.lightBlueAccent),
        SizedBox(width: 6),
        Text(
          LocaleKeys.inspectors.tr(),
          style: TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${provider.inspectors.length} ${LocaleKeys.users.tr()}',
            style: TextStyle(
              color: AppColors.primaryRed,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ProviderAdminUsers provider) {
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
        fillColor: AppColors.lightBlack,
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
          borderSide: BorderSide(color: AppColors.primaryRed),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildUsersList(ProviderAdminUsers provider) {
    if (provider.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if (provider.error != null) {
      return _buildErrorState(provider);
    }

    if (provider.inspectors.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => provider.streamAllInspectors(),
      color: AppColors.primaryRed,
      backgroundColor: AppColors.lightBlack,
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 80),
        key: const PageStorageKey('inspectorsList'),
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: provider.inspectors.length,
        itemBuilder: (context, index) {
          return InspectorCard(inspector: provider.inspectors[index]);
        },
      ),
    );
  }

  Widget _buildErrorState(ProviderAdminUsers provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: AppColors.primaryRed),
          SizedBox(height: 16),
          Text(
            LocaleKeys.error_occurred.tr(),
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
              provider.error!,
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
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

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? LocaleKeys.noUsersAvailable.tr()
                  : LocaleKeys.no_users_found.tr(),
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (_searchController.text.isNotEmpty) ...[
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  context.read<ProviderAdminUsers>().setSearchQuery('');
                },
                child: Text(
                  LocaleKeys.clear_search.tr(),
                  style: TextStyle(color: AppColors.primaryRed),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "addUserFab",
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ScreenAdminCreateUser(),
          ),
        );
      },
      backgroundColor: AppColors.primaryRed,
      icon: Icon(Icons.add, color: Colors.white),
      label: Text(
        LocaleKeys.create_user.tr(),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class InspectorCard extends StatelessWidget {
  final UserModel inspector;

  const InspectorCard({super.key, required this.inspector});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenInspectorDetails(inspector: inspector),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF212121),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: AppColors.primaryRed,
              radius: 22,
              child: Text(
                inspector.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          inspector.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 8,
                      //     vertical: 3,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: _getRoleColor().withValues(alpha: 0.2),
                      //     borderRadius: BorderRadius.circular(10),
                      //     border: Border.all(
                      //       color: _getRoleColor().withValues(alpha: 0.3),
                      //     ),
                      //   ),
                      //   child: Text(
                      //     inspector.role.toUpperCase(),
                      //     style: TextStyle(
                      //       color: _getRoleColor(),
                      //       fontSize: 9,
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    inspector.serviceAccount,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (inspector.region != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          inspector.region!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status & Switch
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (inspector.fcmTokens != null &&
                            inspector.fcmTokens!.isNotEmpty)
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          (inspector.fcmTokens != null &&
                              inspector.fcmTokens!.isNotEmpty)
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (inspector.fcmTokens != null &&
                                inspector.fcmTokens!.isNotEmpty)
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 12,
                        color:
                            (inspector.fcmTokens != null &&
                                inspector.fcmTokens!.isNotEmpty)
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (inspector.fcmTokens != null &&
                                inspector.fcmTokens!.isNotEmpty)
                            ? LocaleKeys.active.tr()
                            : LocaleKeys.loggedOut.tr(),
                        style: TextStyle(
                          color:
                              (inspector.fcmTokens != null &&
                                  inspector.fcmTokens!.isNotEmpty)
                              ? Colors.green
                              : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
