import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
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
        onMapCreated: (GoogleMapController controller){
          _mapController= controller;
        },
        onTap: (LatLng latLang){
          print(latLang);
        },
        onCameraIdle: (){
          print('Dancing animation');
        },
        onCameraMove: (CameraPosition movingPosition){
          print(movingPosition.target);
        },
        onCameraMoveStarted: (){
          print('Hide Animation');
        },

        markers: <Marker>{
          Marker(
              markerId: MarkerId('Home'),
          position: LatLng(23.77976953986539, 90.40301464498043),
            onTap: (){

            },
            visible: true,
            infoWindow: InfoWindow(title: "Home",onTap: (){}),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange
            ),
          ),
          Marker(
              markerId: MarkerId('School'),
              position: LatLng(23.78222370498938, 90.40318630635738),
              onTap: (){

              },
              visible: true,
              infoWindow: InfoWindow(title: "School",onTap: (){})
          ),
          Marker(
              markerId: MarkerId('Office'),
              position: LatLng(23.779573180109416, 90.40682304650545),
              onTap: (){

              },
              visible: true,
              infoWindow: InfoWindow(title: "Office",onTap: (){}),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen
            ),
          ),
        },
        circles: <Circle>{
          Circle(
            circleId: CircleId('red-zone'),
            center: LatLng(23.78222370498938, 90.40318630635738),
            radius: 150,
            strokeWidth: 5,
            fillColor: Colors.red.shade100,
            strokeColor: Colors.red,
          )
        },
          polylines:<Polyline>{
            Polyline(
                polylineId: PolylineId('home to office'),
                points: [
                  LatLng(23.77976953986539, 90.40301464498043),
                  LatLng(23.779573180109416, 90.40682304650545),
                  LatLng(23.78222370498938, 90.40318630635738),
                ],
              width: 10,
              color: Colors.blue,
              endCap: .roundCap,
              startCap: .squareCap,
              visible: true,
              jointType: .round,
            )
          },
        polygons: <Polygon>{
          Polygon(
            polygonId: PolygonId('zone'),
            points: [
              LatLng(23.785854704431504, 90.40611259639263),
              LatLng(23.78487294863716, 90.40488950908184),
              LatLng(23.78336103021315, 90.40555469691753),
              LatLng(23.78365556115527, 90.40759317576885),
              LatLng(23.78517729372637, 90.40753953158855),
            ],
            fillColor: Colors.greenAccent.shade100,
            strokeWidth: 1,
            onTap: (){
              print('Tapped on danger area');
            }

          )
        },
      ) ,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(onPressed: _navigateToHome,child: Icon(Icons.home),),
          FloatingActionButton(onPressed: _navigateToOffice,child: Icon(Icons.home_repair_service_outlined),),
        ],
      ),
    );
  }
  void _navigateToHome(){
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(23.77976953986539, 90.40301464498043),
        zoom: 16,
        )
      )
    );
  }
  void _navigateToOffice(){
    _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(23.779573180109416, 90.40682304650545),
              zoom: 16,
            )
        )
    );
  }
}
