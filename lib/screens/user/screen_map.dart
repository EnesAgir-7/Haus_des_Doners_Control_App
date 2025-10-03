import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../data/dummy_branches.dart';

class BranchMapScreen extends StatefulWidget {
  const BranchMapScreen({super.key});

  @override
  State<BranchMapScreen> createState() => _BranchMapScreenState();
}

class _BranchMapScreenState extends State<BranchMapScreen> {
  GoogleMapController? _mapController;
  DymmyBranch? _selectedBranch;
  final PageController _pageController = PageController(
    viewportFraction: 0.75,
  ); // slightly smaller cards

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    // Only update map when user scrolls, not when tapping
    if (_pageController.page != null &&
        (_pageController.page! % 1).abs() < 0.01) {
      final index = _pageController.page!.round();
      final branch = dummyBranches[index];
      _animateToBranch(branch, animateInfoWindow: false);
    }
  }

  void _animateToBranch(DymmyBranch branch, {bool animateInfoWindow = true}) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(branch.latitude, branch.longitude), 14),
    );
    if (animateInfoWindow) {
      setState(() {
        if (_selectedBranch == branch) {
          _selectedBranch = null; // deselect if tapped again
        } else {
          _selectedBranch = branch;
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                dummyBranches[0].latitude,
                dummyBranches[0].longitude,
              ),
              zoom: 5,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: dummyBranches.map((branch) {
              return Marker(
                markerId: MarkerId(branch.id),
                position: LatLng(branch.latitude, branch.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
                onTap: () => _animateToBranch(branch),
              );
            }).toSet(),
            zoomControlsEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
          ),

          // Bottom scrollable list
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            height: 120, // smaller height for cards
            child: PageView.builder(
              controller: _pageController,
              itemCount: dummyBranches.length,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final branch = dummyBranches[index];
                return _branchCard(branch, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _branchCard(DymmyBranch branch, int index) {
    return GestureDetector(
      onTap: () {
        // Animate page to tapped card
        _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _animateToBranch(branch);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.lightBlack,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              SizedBox(width: 10),
              CachedNetworkImage(
                imageUrl: branch.imageUrl ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                ),
                errorWidget: (context, url, error) =>
                    Icon(Icons.apartment, size: 50, color: Colors.white24),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      branch.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      branch.address,
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    RatingBarIndicator(
                      rating: branch.averageScore ?? 0.0,
                      itemBuilder: (context, index) =>
                          Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 12,
                      unratedColor: Colors.white24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
