import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AssignmentRealTimeLocation extends StatefulWidget {
  const AssignmentRealTimeLocation({super.key});

  @override
  State<AssignmentRealTimeLocation> createState() => _AssignmentRealTimeLocationState();
}

class _AssignmentRealTimeLocationState extends State<AssignmentRealTimeLocation> {

  Position? _currentPosition;
  StreamSubscription? _locationSubscriber;
  GoogleMapController? _mapController;
  bool _isTracking = false;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _polylinePoints = [];

  void _cancelCurrentLocationStream(){
    _locationSubscriber?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-Time Location Tracker'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: false,
              markers: _markers,
              polylines: _polylines,
              initialCameraPosition: CameraPosition(
                target: LatLng(23.781, 90.403),
                zoom: 16,
              ),
              onMapCreated: (GoogleMapController controller){
                _mapController= controller;
                //_initMap();
              }
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: 'go_location',
            onPressed: () async {
              await _initMap();
            },
            child: Icon(Icons.location_history),
          ),

          //my location icon tracking start
          FloatingActionButton(
            heroTag: 'start',
            backgroundColor: Colors.green,
            onPressed: _isTracking ? null : () {
              _startLocationUpdate();
              setState(() => _isTracking = true);
            },
            child: Icon(Icons.my_location),
          ),

          //location disabled icon tracking stop
          FloatingActionButton(
            heroTag: 'stop',
            backgroundColor: Colors.red,
            onPressed: !_isTracking ? null : () {
              _locationSubscriber?.cancel();
              setState(() => _isTracking = false);
            },
            child: Icon(Icons.location_disabled),
          ),
        ],
      ),
    );
  }
  Future<void> _initMap()async{
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    bool hasPermission = await _hasLocationPermission();
    if (!hasPermission) {
      hasPermission = await _requestLocationPermission();
      if (!hasPermission) return;
    }
    _currentPosition = await Geolocator.getCurrentPosition();
    _polylinePoints.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));

    _markers.add(
        Marker(markerId:
        MarkerId('My_Location'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            infoWindow: InfoWindow(
              title: 'My current location',
              snippet: 'Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}',

            )
        )
    );

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 16
        ),
      ),
    );

    setState(() {

    });
    _isTracking = true;
    _startLocationUpdate();
  }


  void _startLocationUpdate() {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _locationSubscriber = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      print('New position: ${position.latitude}, ${position.longitude}');
      _currentPosition = position;
      final newLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId("My_Location"),
            position: newLatLng,
            infoWindow: InfoWindow(
              title: 'My current location',
              snippet: 'Lat: ${position.latitude}, Lng: ${position.longitude}',
            ),
          ),
        );

        _polylinePoints.add(newLatLng);
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: PolylineId('track'),
            points: List.from(_polylinePoints),
            width: 5,
            color: Colors.blue,
          ),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(newLatLng),
      );
    });
  }

  Future<bool> _hasLocationPermission() async {
    LocationPermission permissionStatus = await Geolocator.checkPermission();
    return permissionStatus == LocationPermission.always ||
        permissionStatus == LocationPermission.whileInUse;
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission permissionStatus = await Geolocator.requestPermission();
    return permissionStatus == LocationPermission.always ||
        permissionStatus == LocationPermission.whileInUse;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _locationSubscriber?.cancel();
  }
}
