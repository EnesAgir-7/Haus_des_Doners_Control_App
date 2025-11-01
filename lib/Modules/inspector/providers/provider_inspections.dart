// lib/providers/provider_inspection.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:haus_des_control/Modules/inspector/firebase_services/inspector_inspection_service.dart'; // <-- Adjust path as needed
import 'package:haus_des_control/models/inspection_model.dart';

import '../../../translations/locale_keys.g.dart';

class ProviderInspection extends ChangeNotifier {
  // 1. Instantiate the service internally, just like in ProviderFleet
  final InspectorInspectionService _inspectionService =
      InspectorInspectionService();

  InspectionModel? _inspection;
  bool _isLoading = false;
  String? _errorMessage;

  InspectionModel? get inspection => _inspection;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetches inspection details by ID using the Firebase service.
  Future<void> fetchInspectionDetails(String inspectionId) async {
    // Optional: Prevent fetch if the same ID is already loaded and not currently loading.
    if (_inspection?.id == inspectionId && !_isLoading && _inspection != null) {
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // 2. Call the service method
      final result = await _inspectionService.getInspectionById(inspectionId);

      if (result == null) {
        _inspection = null;
        // Using a localized error message for consistency
        _errorMessage = LocaleKeys.inspectionNotFound.tr();
      } else {
        _inspection = result;
      }
    } catch (e) {
      // Use localization and args for error, similar to ProviderFleet
      _errorMessage =
          '${LocaleKeys.errorLoadingInspection.tr()}: ${e.toString()}';
      _inspection = null;
      print('Error in ProviderInspection: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
