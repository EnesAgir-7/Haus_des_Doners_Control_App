import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/branch_model.dart';

class BranchMapController extends ChangeNotifier {
  GoogleMapController? mapController;
  PageController pageController = PageController(viewportFraction: 0.8);
  BranchModel? _selectedBranch;
  BranchModel? get selectedBranch => _selectedBranch;

  List<BranchModel> _branches = [];
  List<BranchModel> get branches => _branches;

  final Map<String, Marker> markers = {};

  // Initialize with branches list
  void initializeBranches(List<BranchModel> branches) {
    _branches = branches;
    _initMarkers();
    notifyListeners();
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
    _setMapStyle();
  }

  Future<void> _setMapStyle() async {
    if (mapController == null) return;
    try {
      // you can load the map style here
      final style = await rootBundle.loadString(
        'assets/map_styles/dark_map.json',
      );
      mapController?.setMapStyle(style);
    } catch (e) {
      // Handle error if map style file doesn't exist
      debugPrint('Map style not found: $e');
    }
  }

  void _initMarkers() {
    markers.clear();
    for (var branch in _branches) {
      markers[branch.id] = Marker(
        markerId: MarkerId(branch.id),
        position: LatLng(branch.gps.latitude, branch.gps.longitude),
        infoWindow: InfoWindow(title: branch.name, snippet: branch.address),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          branch.isRouteAssigned
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueRed,
        ),
        onTap: () => selectBranch(branch, fromMarker: true),
      );
    }
  }

  void selectBranch(BranchModel branch, {bool fromMarker = false}) {
    _selectedBranch = branch;
    notifyListeners();

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(branch.gps.latitude, branch.gps.longitude),
        14,
      ),
    );

    mapController?.showMarkerInfoWindow(MarkerId(branch.id));

    if (fromMarker) {
      final index = _branches.indexWhere((b) => b.id == branch.id);
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
    if (index < _branches.length) {
      final branch = _branches[index];
      selectBranch(branch);
    }
  }

  @override
  void dispose() {
    mapController?.dispose();
    pageController.dispose();
    super.dispose();
  }
}
