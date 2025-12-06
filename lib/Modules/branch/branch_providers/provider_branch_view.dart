import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/branch/firebase_services/branch_service.dart';
import 'package:haus_des_control/models/branch_model.dart';

import '../../../translations/locale_keys.g.dart';

class ProviderBranchView extends ChangeNotifier {
  BranchModel? branch;
  bool isLoading = false;
  String? error;

  Future<void> loadBranchForUser(String userId) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result = await BranchService.fetchBranchByUserId(userId);
      if (result == null) {
        error = LocaleKeys.branchNotFound.tr();
        branch = null;
      } else {
        branch = result;
      }
    } catch (e) {
      error = e.toString();
      branch = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
