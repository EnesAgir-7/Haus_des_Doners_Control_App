import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/dummy_branches.dart';
import '../models/branch_model.dart';

class BranchMapController extends ChangeNotifier {
  GoogleMapController? mapController;
  PageController pageController = PageController(viewportFraction: 0.8);
  BranchModel? _selectedBranch;
  BranchModel? get selectedBranch => _selectedBranch;

  final Map<String, Marker> markers = {};

  BranchMapController() {
    _initMarkers();
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
    _setMapStyle();
  }

  Future<void> _setMapStyle() async {
    if (mapController == null) return;
    // you can load the map style here
    final style = await rootBundle.loadString(
      'assets/map_styles/dark_map.json',
    );
    mapController?.setMapStyle(style);
  }

  void _initMarkers() {
    for (var branch in dummyBranches) {
      markers[branch.id] = Marker(
        markerId: MarkerId(branch.id),
        position: LatLng(branch.gps.latitude, branch.gps.longitude),
        infoWindow: InfoWindow(title: branch.name, snippet: branch.address),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () => selectBranch(branch, fromMarker: true),
      );
    }
  }

  void selectBranch(BranchModel branch, {bool fromMarker = false}) {
    _selectedBranch = branch;
    notifyListeners();

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(branch.gps.latitude, branch.gps.longitude), 14),
    );

    mapController?.showMarkerInfoWindow(MarkerId(branch.id));

    if (fromMarker) {
      final index = dummyBranches.indexOf(branch);
      if (index != -1) {
        pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void onPageChanged(int index) {
    final branch = dummyBranches[index];
    selectBranch(branch);
  }
}
