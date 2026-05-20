import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {

  Position? _currentPosition;
  StreamSubscription? _locationSubscriber;

  void _listenCurrentLocation(){
    _locationSubscriber= Geolocator.getPositionStream().listen((Position){
      print(Position);
      _currentPosition = Position;
      setState(() {

      });
    });
  }
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Current Location: $_currentPosition',textAlign: TextAlign.center,),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(onPressed: _onTapMyCurrentLocation,child: Icon(Icons.location_history),),
          FloatingActionButton(onPressed: _listenCurrentLocation,child: Icon(Icons.my_location),),
          FloatingActionButton(onPressed: _cancelCurrentLocationStream,child: Icon(Icons.location_disabled),),
        ],
      ),
    );
  }
  Future<void> _onTapMyCurrentLocation() async {

    //check GPS service uses permissions
    bool hasPermission= await _hasLocationPermission();
    if(hasPermission == false){
      //Request permission
      bool requestedPermission =await _requestLocationPermission();
      if(requestedPermission == false){
        return;
      }
    }

    //Check GPS service enable
    bool gpsEnabled= await Geolocator.isLocationServiceEnabled();
    if(gpsEnabled == false){
      Geolocator.openLocationSettings();
      return;
    }
    //Get current Location

    _currentPosition=await Geolocator.getCurrentPosition();
    print(_currentPosition);
    setState(() {
    });
  }
  Future<bool> _hasLocationPermission() async {
    LocationPermission permissionStatus=await Geolocator.checkPermission();
    return permissionStatus == .always || permissionStatus == .whileInUse;
  }
  Future<bool> _requestLocationPermission() async {
    LocationPermission permissionStatus=await Geolocator.requestPermission();
    return permissionStatus == .always || permissionStatus == .whileInUse;
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _locationSubscriber?.cancel();
  }
}
