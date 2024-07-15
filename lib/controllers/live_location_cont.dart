import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_device_name/flutter_device_name.dart";
import "package:geolocator/geolocator.dart";
import "package:get/get.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:location_tracker/res/constants.dart";
import "package:permission_handler/permission_handler.dart";
import "package:wampproto/serializers.dart";
import "package:xconn/exports.dart";

class LocationController extends GetxController {
  Rx<Position?> currentPosition = Rx<Position?>(null);
  Rx<Position?> previousPosition = Rx<Position?>(null);
  RxList<LatLng> routeCoordinates = RxList<LatLng>();
  RxMap<String, Marker> markers = <String, Marker>{}.obs;
  RxMap<String, Polyline> polylines = <String, Polyline>{}.obs;
  GoogleMapController? mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  Rx<DateTime> lastPublishTime = DateTime.now().obs;
  String? deviceName;
  Session? session;
  BitmapDescriptor? arrowIcon;
  double currentZoom = 15;

  Future<void> mobileModelName(double lat, double long) async {
    final plugin = DeviceName();
    deviceName = (await plugin.getName()) ?? "Unknown Device";
    await _publish(lat, long, deviceName!);
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    await _checkLocationPermission();
    await _subscribe();
    await _loadArrowIcon();
  }

  @override
  Future<void> onClose() async {
    await _positionStreamSubscription?.cancel();
    super.onClose();
  }

  Future<void> _checkLocationPermission() async {
    await makeSession();
    PermissionStatus permissionStatus = await Permission.location.status;
    if (permissionStatus.isGranted) {
      _startLocationUpdates();
    } else {
      PermissionStatus permissionResult = await Permission.location.request();
      if (permissionResult.isGranted) {
        _startLocationUpdates();
        Get.snackbar("Location", "Permission Granted Successfully");
      } else if (permissionResult.isDenied) {
        Get.snackbar("Location", "Permission is Denied");
      } else if (permissionResult.isPermanentlyDenied) {
        Get.snackbar(
          "Location",
          "Permission is Denied Permanently. Please Allow Permission to run the app without any issue",
        );
        await openAppSettings();
      }
      return;
    }
  }

  void _startLocationUpdates() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) async {
      previousPosition.value = currentPosition.value;
      currentPosition.value = position;
      routeCoordinates.add(LatLng(position.latitude, position.longitude));
      await mobileModelName(position.latitude, position.longitude);
      _updateMarker();
      _updatePolyline();
      await _moveCamera();
      await _refreshPublish(position.latitude, position.longitude);
    });
  }

  Future<void> _loadArrowIcon() async {
    arrowIcon = await BitmapDescriptor.asset(
      ImageConfiguration(devicePixelRatio: currentZoom),
      "assets/arrow_icon.png",
    );
    update();
  }

  void _updateMarker() {
    if (currentPosition.value != null && previousPosition.value != null) {
      double bearing = Geolocator.bearingBetween(
        previousPosition.value!.latitude,
        previousPosition.value!.longitude,
        currentPosition.value!.latitude,
        currentPosition.value!.longitude,
      );

      markers[deviceName!] = Marker(
        markerId: MarkerId(deviceName!),
        position: LatLng(
          currentPosition.value!.latitude,
          currentPosition.value!.longitude,
        ),
        infoWindow: InfoWindow(
          title: deviceName,
          snippet: "${currentPosition.value!.latitude}, ${currentPosition.value!.longitude}",
        ),
        icon: arrowIcon!,
        rotation: bearing,
        anchor: const Offset(0.5, 0.5),
      );
      update();
    }
  }

  void _updatePolyline() {
    if (routeCoordinates.length > 1) {
      polylines[deviceName!] = Polyline(
        polylineId: PolylineId(deviceName!),
        points: routeCoordinates.toList(),
        color: Colors.red,
        width: 5,
      );
      update();
    }
  }

  Future<void> _moveCamera() async {
    if (currentPosition.value != null && mapController != null) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(currentPosition.value!.latitude, currentPosition.value!.longitude),
        ),
      );
    }
  }

  Future<void> makeSession() async {
    var client = Client(serializer: JSONSerializer());
    session = await client.connect(
      urlLink,
      realm,
    );
  }

  Future<void> onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    await _moveCamera();
  }

  Future<void> onCameraMove(CameraPosition position) async {
    currentZoom = position.zoom;
    await _loadArrowIcon();
  }

  Future<void> _publish(double latitude, double longitude, String name) async {
    try {
      await session?.publish(
        topicName,
        args: [latitude, longitude, name],
        kwargs: {},
      );
    } on Exception catch (e) {
      return Future.error(e);
    }
  }

  Future<void> _refreshPublish(double latitude, double longitude) async {
    final now = DateTime.now();
    if (now.difference(lastPublishTime.value).inSeconds >= 2) {
      lastPublishTime.value = now;
      await _publish(latitude, longitude, deviceName!);
    }
  }

  Future<void> _subscribe() async {
    try {
      await session?.subscribe(
        topicName,
        (event) {
          List<dynamic> args = event.args;
          if (args.length < 3) {
            throw Exception("Insufficient arguments received: ${args.length}");
          }
          String name = args[2];
          double parseCoordinate(value) {
            if (value is double) {
              return value;
            } else if (value is String) {
              return double.parse(value);
            } else {
              throw Exception("Unexpected type for coordinate: ${value.runtimeType}");
            }
          }

          double latitude = parseCoordinate(args[0]);
          double longitude = parseCoordinate(args[1]);
          updateOtherLocation(name, latitude, longitude);
        },
      );
    } on Exception catch (error) {
      Get.snackbar("Error", "Error connecting or subscribing: $error");
    }
  }

  void updateOtherLocation(String name, double latitude, double longitude) {
    var deviceRouteCoordinates = (polylines[name]?.points.toList() ?? <LatLng>[])..add(LatLng(latitude, longitude));
    polylines[name] = Polyline(
      polylineId: PolylineId(name),
      points: deviceRouteCoordinates,
      color: Colors.red,
      width: 5,
    );

    markers[name] = Marker(
      markerId: MarkerId(name),
      position: LatLng(latitude, longitude),
      infoWindow: InfoWindow(
        title: name,
        snippet: "$latitude, $longitude",
      ),
      icon: arrowIcon!,
      rotation: Geolocator.bearingBetween(
        previousPosition.value?.latitude ?? latitude,
        previousPosition.value?.longitude ?? longitude,
        latitude,
        longitude,
      ),
      anchor: const Offset(0.5, 0.5),
    );

    update();
  }
}
