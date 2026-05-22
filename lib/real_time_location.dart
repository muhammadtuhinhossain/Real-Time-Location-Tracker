import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AssignmentLocationMapScreen extends StatefulWidget {
  const AssignmentLocationMapScreen({super.key});

  @override
  State<AssignmentLocationMapScreen> createState() =>
      _AssignmentLocationMapScreenState();
}

class _AssignmentLocationMapScreenState
    extends State<AssignmentLocationMapScreen> {
  // ─── Map Controller ───────────────────────────────────────────────────────
  GoogleMapController? _mapController;

  // ─── Location State ───────────────────────────────────────────────────────
  Position? _currentPosition;
  LatLng? _previousLatLng;
  LatLng? _currentLatLng;

  // ─── Map Overlays ─────────────────────────────────────────────────────────
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylinePoints = [];

  // ─── Timer for 10-second updates ──────────────────────────────────────────
  Timer? _locationTimer;

  // ─── Tracking state ───────────────────────────────────────────────────────
  bool _isTracking = false;
  bool _isLoading = false;

  // ─── User manually dragging/zooming the map ───────────────────────────────
  bool _userInteracting = false;

  // ─── Marker ID ────────────────────────────────────────────────────────────
  static const _myLocationMarkerId = MarkerId('my_current_location');

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initLocationAndStart();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> _initLocationAndStart() async {
    setState(() => _isLoading = true);

    bool hasPermission = await _hasLocationPermission();
    if (!hasPermission) {
      hasPermission = await _requestLocationPermission();
    }
    if (!hasPermission) {
      setState(() => _isLoading = false);
      _showSnackBar('Location permission denied!');
      return;
    }

    bool gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      await Geolocator.openLocationSettings();
      setState(() => _isLoading = false);
      return;
    }

    // Fetch initial location and animate map
    await _fetchAndUpdateLocation();
    setState(() => _isLoading = false);

    // Start 10-second periodic updates
    _startLocationTracking();
  }

  // ─── Permission Helpers ───────────────────────────────────────────────────

  Future<bool> _hasLocationPermission() async {
    final status = await Geolocator.checkPermission();
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  Future<bool> _requestLocationPermission() async {
    final status = await Geolocator.requestPermission();
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  // ─── Location Fetch & Map Update ─────────────────────────────────────────

  /// Fetches current location, updates marker, polyline, and animates camera.
  Future<void> _fetchAndUpdateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _previousLatLng = _currentLatLng;
        _currentLatLng = newLatLng;
        _currentPosition = position;

        // ── 1. Update Marker with InfoWindow (lat/lng snippet) ──────────────
        _markers.removeWhere((m) => m.markerId == _myLocationMarkerId);
        _markers.add(
          Marker(
            markerId: _myLocationMarkerId,
            position: newLatLng,
            visible: true,
            infoWindow: InfoWindow(
              title: 'My current location',
              snippet:
              'Lat: ${position.latitude.toStringAsFixed(6)}, '
                  'Lng: ${position.longitude.toStringAsFixed(6)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            // Tapping the marker opens the InfoWindow automatically
            onTap: () {
              _mapController?.showMarkerInfoWindow(_myLocationMarkerId);
            },
          ),
        );

        // ── 2. Update Polyline (previous → current) ──────────────────────────
        if (_previousLatLng != null) {
          _polylinePoints.add(_currentLatLng!);

          _polylines.removeWhere(
                (p) => p.polylineId == const PolylineId('location_trail'),
          );
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('location_trail'),
              points: List.from(_polylinePoints),
              width: 5,
              color: Colors.deepPurple,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
          );
        } else {
          // First point — add it as the starting point
          _polylinePoints.add(newLatLng);
        }
      });

      // ── 3. শুধু position update করো, zoom যা আছে তাই থাকবে ─────────────
      if (!_userInteracting) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(newLatLng), // zoom touch করবে না
        );
      }
    } catch (e) {
      debugPrint('Location fetch error: $e');
    }
  }

  // ─── 10-Second Timer ──────────────────────────────────────────────────────

  void _startLocationTracking() {
    _locationTimer?.cancel();
    _isTracking = true;
    _userInteracting = false; // user interaction reset

    // Play button চাপলে zoom 16 এ ফিরে যাবে
    if (_currentLatLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLatLng!, zoom: 16),
        ),
      );
    }

    // Immediately fetch, then every 10 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchAndUpdateLocation();
    });

    setState(() {});
  }

  void _stopLocationTracking() {
    _locationTimer?.cancel();
    setState(() => _isTracking = false);
  }

  // ─── UI Helpers ───────────────────────────────────────────────────────────

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location Tracker'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Show tracking status indicator
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isTracking
                ? const Tooltip(
              message: 'Tracking active (every 10s)',
              child: Icon(Icons.location_on, color: Colors.greenAccent),
            )
                : const Tooltip(
              message: 'Tracking stopped',
              child: Icon(Icons.location_off, color: Colors.white54),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Google Map ───────────────────────────────────────────────────
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            trafficEnabled: false,
            markers: _markers,
            polylines: _polylines,
            initialCameraPosition: CameraPosition(
              // Default center — will animate to user's location on init
              target: _currentLatLng ?? const LatLng(23.781, 90.403),
              zoom: 17,
            ),
            onCameraMoveStarted: () {
              _userInteracting = true;
            },
            onCameraIdle: () {
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) setState(() => _userInteracting = false);
              });
            },
            onMapCreated: (controller) {
              _mapController = controller;
              // If location already loaded before map was ready, animate now
              if (_currentLatLng != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _currentLatLng!, zoom: 17),
                  ),
                );
              }
            },
          ),

          // ── Loading Overlay ───────────────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.deepPurple),
                    SizedBox(height: 16),
                    Text(
                      'Fetching your location...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // ── Location Info Card (bottom) ────────────────────────────────────
          if (_currentPosition != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_pin, color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text(
                            'My Current Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isTracking
                            ? '🟢 Auto-updating every 10 seconds'
                            : '🔴 Tracking paused',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isTracking ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      // ── FABs ────────────────────────────────────────────────────────────────
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Animate to current location
          FloatingActionButton(
            heroTag: 'center',
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            tooltip: 'Go to my location',
            onPressed: _currentLatLng == null
                ? null
                : () {
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: _currentLatLng!, zoom: 17),
                ),
              );
            },
            child: const Icon(Icons.my_location),
          ),

          // Start tracking
          FloatingActionButton(
            heroTag: 'start',
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            tooltip: 'Start tracking',
            onPressed: _isTracking ? null : _startLocationTracking,
            child: const Icon(Icons.play_arrow),
          ),

          // Stop tracking
          FloatingActionButton(
            heroTag: 'stop',
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            tooltip: 'Stop tracking',
            onPressed: _isTracking ? _stopLocationTracking : null,
            child: const Icon(Icons.stop),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}