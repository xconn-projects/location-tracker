import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:location_tracker/controllers/live_location_cont.dart";
import "package:location_tracker/res/constants.dart";

class LiveTrackingScreen extends StatelessWidget {
  LiveTrackingScreen({super.key});

  final LocationController _locationController = Get.put(LocationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location Tracker"),
      ),
      body: Obx(() {
        return _locationController.currentPosition.value == null
            ? spinKitRotatingCircle
            : GoogleMap(
                onMapCreated: _locationController.onMapCreated,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(30.1917228, 71.4431091),
                  zoom: 14,
                ),
                markers: Set<Marker>.of(_locationController.markers.values),
                polylines: Set<Polyline>.of(_locationController.polylines.values),
              );
      }),
    );
  }
}
