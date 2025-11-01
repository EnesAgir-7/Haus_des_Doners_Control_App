import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../core/constants/app_colors.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/widgets/app_button.dart';

class LocationPickerDialog extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String googleMapsApiKey;

  const LocationPickerDialog({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.googleMapsApiKey,
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  String _address = '';
  double _selectedLatitude = 51.1657; // Default: Germany center
  double _selectedLongitude = 10.4515;

  Set<Marker> _markers = {};
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude ?? 51.1657;
    _selectedLongitude = widget.initialLongitude ?? 10.4515;

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _updateMarker(_selectedLatitude, _selectedLongitude);
      _getAddressFromLatLng(_selectedLatitude, _selectedLongitude);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _updateMarker(double lat, double lng) {
    setState(() {
      _selectedLatitude = lat;
      _selectedLongitude = lng;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address =
              '${place.street ?? ''}, ${place.postalCode ?? ''} ${place.locality ?? ''}, ${place.country ?? ''}'
                  .trim();
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
        'input=$query&'
        'components=country:de&' // Restrict to Germany
        'key=${widget.googleMapsApiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['predictions'] ?? [];
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _selectSearchResult(dynamic prediction) async {
    final placeId = prediction['place_id'];

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId&'
        'fields=geometry,formatted_address&'
        'key=${widget.googleMapsApiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = data['result']['geometry']['location'];
        final address = data['result']['formatted_address'];

        final lat = location['lat'];
        final lng = location['lng'];

        _updateMarker(lat, lng);
        setState(() {
          _address = address;
          _searchResults = [];
          _searchController.text = address;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
        );
      }
    } catch (e) {
      debugPrint('Error getting place details: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      _updateMarker(position.latitude, position.longitude);
      await _getAddressFromLatLng(position.latitude, position.longitude);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: Stack(
                children: [
                  _buildMapView(),
                  if (_searchResults.isNotEmpty) _buildSearchResults(),
                ],
              ),
            ),
            _buildLocationInfo(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.location_on,
              color: AppColors.primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.pickLocation.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  LocaleKeys.searchOrTapOnMap.tr(),
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                hintText: LocaleKeys.searchLocation.tr(),
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                  _searchPlaces(value);
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _getCurrentLocation,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.my_location,
                color: AppColors.primaryRed,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: _isSearching
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.white.withValues(alpha: 0.1),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final prediction = _searchResults[index];
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: AppColors.primaryRed,
                      size: 20,
                    ),
                    title: Text(
                      prediction['structured_formatting']['main_text'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      prediction['structured_formatting']['secondary_text'] ??
                          '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    onTap: () => _selectSearchResult(prediction),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_selectedLatitude, _selectedLongitude),
        zoom: 12,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      onTap: (position) {
        _updateMarker(position.latitude, position.longitude);
        _getAddressFromLatLng(position.latitude, position.longitude);
      },
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.place, color: AppColors.primaryRed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _address.isEmpty ? LocaleKeys.tapOnMapToSelect.tr() : _address,
              style: TextStyle(
                color: _address.isEmpty
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: AppButton(
        text: LocaleKeys.confirmLocation.tr(),
        icon: Icons.check,
        onPressed: _address.isNotEmpty ? _confirmLocation : null,
      ),
    );
  }

  void _confirmLocation() {
    Navigator.of(context).pop({
      'latitude': _selectedLatitude,
      'longitude': _selectedLongitude,
      'address': _address,
    });
  }
}

// Helper function to show the dialog
Future<Map<String, dynamic>?> showLocationPickerDialog(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
  required String googleMapsApiKey,
}) async {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => LocationPickerDialog(
      initialLatitude: initialLatitude,
      initialLongitude: initialLongitude,
      googleMapsApiKey: googleMapsApiKey,
    ),
  );
}
