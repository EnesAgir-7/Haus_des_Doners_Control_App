import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/core/constants/app_constants.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../translations/locale_keys.g.dart';
import 'screen_admin_create_user.dart';
import 'screen_admin_user_details.dart';
//TODO: locale
class ScreenAdminOtherUser extends StatefulWidget {
  final String role;
  const ScreenAdminOtherUser({super.key, required this.role});

  @override
  State<ScreenAdminOtherUser> createState() => _ScreenAdminOtherUserState();
}

class _ScreenAdminOtherUserState extends State<ScreenAdminOtherUser> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserModel>? _cachedUsers;
  bool _isInitialLoad = true;
  String? _cachedRole; // Track which role the cache is for

  @override
  void initState() {
    super.initState();
    _cachedRole = widget.role;
  }

  @override
  void didUpdateWidget(ScreenAdminOtherUser oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset cache if role changes
    if (oldWidget.role != widget.role) {
      setState(() {
        _cachedUsers = null;
        _isInitialLoad = true;
        _cachedRole = widget.role;
        _searchController.clear();
        _searchQuery = '';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    if (_searchQuery.isEmpty) return users;

    final query = _searchQuery.toLowerCase();
    return users.where((u) {
      return u.name.toLowerCase().contains(query) ||
          u.serviceAccount.toLowerCase().contains(query) ||
          (u.region?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(Collections.inspectors)
                .where(UserFields.role, isEqualTo: widget.role)
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              // Only cache data if it's for the current role
              if (snapshot.hasData &&
                  _isInitialLoad &&
                  _cachedRole == widget.role) {
                _cachedUsers = snapshot.data!.docs
                    .map((doc) => UserModel.fromFirestore(doc))
                    .toList();
                _isInitialLoad = false;
              }

              // Use cached data only if it matches current role
              final List<UserModel> users = snapshot.hasData
                  ? snapshot.data!.docs
                        .map((doc) => UserModel.fromFirestore(doc))
                        .toList()
                  : (_cachedRole == widget.role ? (_cachedUsers ?? []) : []);

              // Remove the current logged-in admin from the list (only for admin role)
              if (loggedInUser?.id != null &&
                  widget.role == AppConstants.admin) {
                users.removeWhere((u) => u.id == loggedInUser!.id);
              }

              final filteredUsers = _filterUsers(users);
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                  (_cachedUsers == null || _cachedRole != widget.role);
              final hasError =
                  snapshot.hasError &&
                  (_cachedUsers == null || _cachedRole != widget.role);

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(users.length),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    Container(height: 1, color: Colors.white24),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildUsersList(
                        filteredUsers,
                        isLoading,
                        hasError,
                        snapshot.error?.toString(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: widget.role == AppConstants.admin
          ? _buildFAB(context)
          : null,
    );
  }

  Widget _buildHeader(int totalCount) {
    return Row(
      children: [
        const Icon(Icons.admin_panel_settings, color: Colors.lightBlueAccent),
        const SizedBox(width: 6),
        Text(
          widget.role == AppConstants.admin
              ? LocaleKeys.admins.tr()
              : LocaleKeys.branchManagers.tr(),
          style: const TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$totalCount ${LocaleKeys.users.tr()}',
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: LocaleKeys.search.tr(),
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
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
          borderSide: const BorderSide(color: AppColors.primaryRed),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildUsersList(
    List<UserModel> users,
    bool isLoading,
    bool hasError,
    String? errorMessage,
  ) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if (hasError) {
      return _buildErrorState(errorMessage);
    }

    if (users.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      key: PageStorageKey('usersList_${widget.role}'),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return AdminCard(admin: users[index]);
      },
    );
  }

  Widget _buildErrorState(String? errorMessage) {
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
            LocaleKeys.error_occurred.tr(),
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
              errorMessage ?? LocaleKeys.unknownError.tr(),
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _cachedUsers = null;
                _isInitialLoad = true;
                _cachedRole = widget.role;
              });
            },
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
    // Determine the appropriate message based on role
    String emptyMessage;
    if (_searchController.text.isNotEmpty) {
      emptyMessage = LocaleKeys.no_users_found.tr();
    } else {
      emptyMessage = widget.role == AppConstants.admin
          ? LocaleKeys.noAdminsAvailable.tr()
          : "No Branch Managers Available";
    }

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
                child: Text(
                  LocaleKeys.clear_search.tr(),
                  style: const TextStyle(color: AppColors.primaryRed),
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
      heroTag: "addAdminFab_${widget.role}",
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ScreenAdminCreateUser(),
          ),
        );
      },
      backgroundColor: AppColors.primaryRed,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        LocaleKeys.create_user.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  final UserModel admin;

  const AdminCard({super.key, required this.admin});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenAdminUserDetails(user: admin),
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
                admin.name[0].toUpperCase(),
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
                  Text(
                    admin.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    admin.serviceAccount,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (admin.region != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            admin.region!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (admin.fcmTokens != null && admin.fcmTokens!.isNotEmpty)
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      (admin.fcmTokens != null && admin.fcmTokens!.isNotEmpty)
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (admin.fcmTokens != null && admin.fcmTokens!.isNotEmpty)
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: 12,
                    color:
                        (admin.fcmTokens != null && admin.fcmTokens!.isNotEmpty)
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    (admin.fcmTokens != null && admin.fcmTokens!.isNotEmpty)
                        ? LocaleKeys.active.tr()
                        : LocaleKeys.loggedOut.tr(),
                    style: TextStyle(
                      color:
                          (admin.fcmTokens != null &&
                              admin.fcmTokens!.isNotEmpty)
                          ? Colors.green
                          : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
