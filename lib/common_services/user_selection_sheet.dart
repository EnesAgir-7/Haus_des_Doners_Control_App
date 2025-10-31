import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Modules/admin/admin_providers/provider_admin_users.dart';
import '../core/constants/app_colors.dart';

Future<dynamic> showInspectorPicker({
  required BuildContext context,
  String? selectedInspectorId, // pass currently selected inspector if any
}) async {
  final adminUsersProvider = context.read<ProviderAdminUsers>();
  final inspectors = adminUsersProvider.inspectors;

  return await showModalBottomSheet<dynamic>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.lightBlack,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha:  0.08),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Select Inspector',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha:  0.7),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: adminUsersProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryRed,
                        ),
                      ),
                    )
                  : inspectors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off_rounded,
                            size: 48,
                            color: Colors.white.withValues(alpha:  0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No inspectors available',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:  0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: inspectors.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final inspector = inspectors[index];
                        final isSelected = selectedInspectorId == inspector.id;

                        return InkWell(
                          onTap: () {
                            Navigator.pop(context, inspector);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryRed.withValues(alpha:  0.15)
                                  : Colors.white.withValues(alpha:  0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryRed.withValues(alpha:  0.4)
                                    : Colors.white.withValues(alpha:  0.06),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isSelected
                                      ? AppColors.primaryRed
                                      : Colors.white.withValues(alpha:  0.1),
                                  child: Text(
                                    inspector.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withValues(alpha:  0.7),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inspector.name,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha:  0.9),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        inspector.serviceAccount,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha:  0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primaryRed,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
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
