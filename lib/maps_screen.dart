import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps'),
        centerTitle: true,
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        trafficEnabled: true,
        myLocationEnabled: true,

        initialCameraPosition: CameraPosition(
          target: LatLng(23.78104086987887, 90.4035401913044),
      zoom: 16,
      ),
      ) ,
    );
  }
}
