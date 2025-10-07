import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/provider_admin_users.dart';
import '../../providers/provider_auth.dart';
import '../../translations/locale_keys.g.dart';
import 'screen_admin_user_details.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  void _loadUsers() {
    final currentUserId = context.read<ProviderAuth>().currentUser?.uid ?? '';
    context.read<ProviderAdminUsers>().loadUsers(currentUserId);
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
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: LocaleKeys.search.tr(),
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              context.read<ProviderAdminUsers>().setSearchQuery(value);
            },
          ),
        ),
        Expanded(
          child: Consumer<ProviderAdminUsers>(
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
                        onPressed: () {
                          final currentUserId =
                              context.read<ProviderAuth>().currentUser?.uid ??
                              '';
                          provider.loadUsers(currentUserId);
                        },
                        child: Text(LocaleKeys.retry.tr()),
                      ),
                    ],
                  ),
                );
              }

              final users = provider.users;
              if (users.isEmpty) {
                if (_searchController.text.isNotEmpty) {
                  return Center(child: Text(LocaleKeys.no_users_found.tr()));
                }
                return Center(child: Text(LocaleKeys.no_users_available.tr()));
              }

              return RefreshIndicator(
                onRefresh: () {
                  final currentUserId =
                      context.read<ProviderAuth>().currentUser?.uid ?? '';
                  return provider.loadUsers(currentUserId);
                },
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _UserListItem(user: user);
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

class _UserListItem extends StatefulWidget {
  final UserModel user;

  const _UserListItem({super.key, required this.user});

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  late UserModel user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  void _handleUserUpdated(UserModel updatedUser) {
    setState(() {
      user = updatedUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.lightBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.primaryRed),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminUserDetailsScreen(
                initialUser: user,
                onUserUpdated: _handleUserUpdated,
              ),
            ),
          );
        },
        child: ListTile(
          leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),
          title: Text(user.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email),
              Text(
                '${LocaleKeys.role.tr()}: ${user.role.toUpperCase()}',
                style: TextStyle(
                  color: user.isAdmin ? Colors.red : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (user.region != null)
                Text('${LocaleKeys.region.tr()}: ${user.region}'),
            ],
          ),
          trailing: Switch(
            value: user.active,
            onChanged: (value) {
              context.read<ProviderAdminUsers>().toggleUserActive(
                user.id,
                value,
              );
            },
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}
