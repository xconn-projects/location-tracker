import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:location_tracker/live_tracking.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Location Tracker",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: LiveTrackingScreen(),
    );
  }
}
