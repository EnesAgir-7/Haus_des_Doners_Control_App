import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/branch/branch_providers/provider_branch_dashboard.dart';
import 'package:haus_des_control/Modules/inspector/providers/provider_branches.dart';
import 'package:haus_des_control/Modules/inspector/providers/provider_panel.dart';
import 'package:provider/provider.dart';

import '../Modules/admin/admin_providers/provider_admin_branches.dart';
import '../Modules/admin/admin_providers/provider_admin_tasks.dart';
import '../Modules/admin/admin_providers/provider_admin_users.dart';
import '../Modules/admin/admin_providers/provider_admin_vehicle.dart';
import '../Modules/inspector/providers/provider_route.dart';
import '../Modules/inspector/providers/provider_tasks.dart';
import '../Modules/inspector/providers/provider_vehicle.dart';
import '../Modules/common/providers/provider_inspector_records.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/firebase_constants.dart';
import '../core/console.dart';

class ProviderCleanupService {
  /// Cleans up all provider streams based on the logged-in user's role
  static Future<void> cleanupAllProviders(BuildContext context) async {
    try {
      final userRole = loggedInUser?.role;

      if (userRole == null) {
        console('⚠️ No user role found, skipping provider cleanup');
        return;
      }

      console('跑 Starting cleanup streams for role: $userRole');

      // Shared providers cleanup
      context.read<ProviderInspectorRecords>().cancelAllStreams();

      switch (userRole) {
        case AppConstants.admin:
          await _cleanupAdminProviders(context);
          break;

        case AppConstants.inspector:
          await _cleanupInspectorProviders(context);
          break;

        case AppConstants.branch:
          await _cleanupBranchProviders(context);
          break;

        default:
          console('⚠️ Unknown role: $userRole');
      }

      console('✅ All provider streams cleaned up for role: $userRole');
    } catch (e, stackTrace) {
      console('❌ Error cleaning up providers: $e\n$stackTrace');
    }
  }

  /// Cleanup providers for Admin role
  static Future<void> _cleanupAdminProviders(BuildContext context) async {
    console('🧹 Cleaning up Admin providers...');

    final futures = <Future<void>>[];

    try {
      // Cancel all streams in parallel
      futures.add(
        Future(() => context.read<ProviderAdminUsers>().cancelAllStreams()),
      );
      futures.add(
        Future(() => context.read<ProviderAdminVehicles>().cancelAllStreams()),
      );
      futures.add(
        Future(() => context.read<ProviderAdminBranches>().cancelAllStreams()),
      );
      futures.add(
        Future(() => context.read<ProviderAdminTasks>().cancelAllStreams()),
      );
      // futures.add(Future(() => context.read<ProviderAdminInspections>().cancelAllStreams()));
      // futures.add(Future(() => context.read<ProviderAdminAnnouncements>().cancelAllStreams()));

      // Wait for all cancellations to complete
      await Future.wait(futures);

      console('✅ Admin providers cleaned up');
    } catch (e) {
      console('⚠️ Error cleaning up admin providers: $e');
    }
  }

  /// Cleanup providers for Inspector role
  static Future<void> _cleanupInspectorProviders(BuildContext context) async {
    console('🧹 Cleaning up Inspector providers...');

    final futures = <Future<void>>[];

    try {
      // Cancel all streams in parallel
      futures.add(
        Future(() => context.read<ProviderPanel>().cancelAllStreams()),
      );
      futures.add(
        Future(() => context.read<ProviderRoute>().cancelAllStreams()),
      );
      futures.add(
        Future(() => context.read<ProviderBranches>().cancelAllStreams()),
      );
      futures.add(
        Future(() => context.read<ProviderVehicle>().cancelAllStreams()),
      );
      futures.add(
        Future(() => context.read<ProviderTasks>().cancelAllStreams()),
      );

      // Wait for all cancellations to complete
      await Future.wait(futures);

      console('✅ Inspector providers cleaned up');
    } catch (e) {
      console('⚠️ Error cleaning up inspector providers: $e');
    }
  }

  /// Cleanup providers for Branch role
  static Future<void> _cleanupBranchProviders(BuildContext context) async {
    console('🧹 Cleaning up Branch providers...');

    final futures = <Future<void>>[];

    try {
      // Cancel all streams in parallel
      futures.add(
        Future(() => context.read<ProviderBranchDashboard>().closeAllStreams()),
      );
      // futures.add(Future(() => context.read<ProviderBranchInspections>().cancelAllStreams()));
      // futures.add(Future(() => context.read<ProviderBranchTasks>().cancelAllStreams()));
      // futures.add(Future(() => context.read<ProviderBranchAnnouncements>().cancelAllStreams()));

      // Wait for all cancellations to complete
      await Future.wait(futures);

      console('✅ Branch providers cleaned up');
    } catch (e) {
      console('⚠️ Error cleaning up branch providers: $e');
    }
  }

  /// Force cleanup all providers regardless of role (use with caution)
  static Future<void> forceCleanupAllProviders(BuildContext context) async {
    console('⚠️ Force cleaning up ALL providers');

    // Run all cleanups in parallel
    await Future.wait([
      _cleanupAdminProviders(context),
      _cleanupInspectorProviders(context),
      _cleanupBranchProviders(context),
    ]);

    console('✅ Force cleanup completed');
  }
}
