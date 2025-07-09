import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/gestures.dart';

class SimpleMapState extends State<StatefulWidget> {
  SimpleMapState();
  HereMapController? hereMapController;

  // Default camera position (Berlin area from your POC)
  GeoCoordinates defaultCenter = GeoCoordinates(52.54014, 13.37958);
  double defaultZoom = 8000; // Distance in meters
  
  _onMapCreated(HereMapController mapController) async {
    this.hereMapController = mapController;
    
    // Set initial camera position
    const double distanceToEarthInMeters = 8000;
    MapMeasure mapMeasureZoom = MapMeasure(MapMeasureKind.distanceInMeters, distanceToEarthInMeters);
    mapController.camera.lookAtPointWithMeasure(defaultCenter, mapMeasureZoom);
    
    // Load the map scene with 3D terrain support
    
    mapController.mapScene.loadSceneForMapScheme(MapScheme.hybridDay, (MapError? error) {
      if (error != null) {
        print('Map scene not loaded. MapError: ${error.toString()}');
      } else {
        _enable3DTerrain(mapController);
        onMapCreated();
      }
    });
  }

  void _enable3DTerrain(HereMapController mapController) {
    try {
      // Enable 3D terrain features
      // mapController.mapScene.enableFeatures({MapFeatures.terrain: "enabled"});
      mapController.mapScene.enableFeatures({MapFeatures.terrain: MapFeatureModes.terrain3d});

      // Set camera to show terrain better - slightly tilted view
      // _setTerrainFriendlyCamera(mapController);
      
      print("3D terrain enabled successfully");
    } catch (e) {
      print("Failed to enable 3D terrain: $e");
    }
  }

  // void _setTerrainFriendlyCamera(HereMapController mapController) {
  //   // Create a camera update that shows terrain with a tilted perspective
  //   GeoOrientationUpdate geoOrientationUpdate = GeoOrientationUpdate(
  //     bearing: 0.0, // North facing
  //     tilt: 60.0,   // Tilted view to show terrain elevation
  //   );
    
  //   MapCameraUpdate mapCameraUpdate = MapCameraUpdateFactory.newGeoOrientationUpdate(
  //     geoOrientationUpdate
  //   );
    
  //   // Apply the camera update
  //   mapController.camera.updateCamera(mapCameraUpdate);
  // }

  onMapCreated() async {
    // You can add your own map created logic here
    // For example, you can initialize sources, layers, or annotations
    print("HERE Map created with center: $defaultCenter and 3D terrain enabled");
    
    // Move to Berlin area where test elements are located
    _moveToTestElementsLocation();
  }

  void _moveToTestElementsLocation() {
    if (hereMapController != null) {
      // Move to Berlin area where our test elements are located
      // Updated center coordinates for 1000 elements spread across wider area
      GeoCoordinates testElementsLocation = GeoCoordinates(52.52000, 13.40500); // Berlin area center
      const double distanceToEarthInMeters = 25000; // Much wider zoom to see all 1000 elements spread out
      MapMeasure mapMeasureZoom = MapMeasure(MapMeasureKind.distanceInMeters, distanceToEarthInMeters);
      
      hereMapController!.camera.lookAtPointWithMeasure(testElementsLocation, mapMeasureZoom);
      
      // Keep a flat view for better element visibility
      // _setTerrainFriendlyCamera(hereMapController!);
    }
  }

  onStyleLoaded() async {
    // You can add your own style loaded logic here
  }

  onResourceRequest() {
    // You can add your own resource request logic here
  }

  Future<void> onTapListener(GeoCoordinates? coordinates) async {
    // You can add your own tap listener logic here
    if (coordinates != null) {
      print('Tapped at: ${coordinates.latitude}, ${coordinates.longitude}');
    }
  }

  Future<void> onLongTapListener(GeoCoordinates? coordinates) async {
    // You can add your own long tap listener logic here
    if (coordinates != null) {
      print('Long tapped at: ${coordinates.latitude}, ${coordinates.longitude}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return HereMap(
      onMapCreated: _onMapCreated,
    );
  }

  @override
  void dispose() {
    // Clean up HERE SDK resources
    _disposeHERESDK();
    super.dispose();
  }

  void _disposeHERESDK() async {
    // Free HERE SDK resources when the widget is disposed
    // Note: In a full app, you might want to manage this at the app level
    // rather than for each map widget
  }
}

// Helper class for map tap handling
class MapTapListener implements TapListener {
  final Function(GeoCoordinates?) onTapCallback;
  final HereMapController? mapController;
  
  MapTapListener(this.onTapCallback, this.mapController);
  
  @override
  void onTap(Point2D origin) {
    GeoCoordinates? geoCoordinates = mapController?.viewToGeoCoordinates(origin);
    onTapCallback(geoCoordinates);
  }
}

// Helper class for map long press handling
class MapLongPressListener implements LongPressListener {
  final Function(GeoCoordinates?) onLongPressCallback;
  final HereMapController? mapController;
  
  MapLongPressListener(this.onLongPressCallback, this.mapController);
  
  @override
  void onLongPress(GestureState gestureState, Point2D origin) {
    GeoCoordinates? geoCoordinates = mapController?.viewToGeoCoordinates(origin);
    onLongPressCallback(geoCoordinates);
  }
}
