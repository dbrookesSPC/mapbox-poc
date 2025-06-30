/*
 * Copyright (C) 2019-2025 HERE Europe B.V.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 * License-Filename: LICENSE
 */

import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/gestures.dart';

void main() async {
  // Usually, you need to initialize the HERE SDK only once during the lifetime of an application.
  await _initializeHERESDK();

  runApp(MyApp());
}

Future<void> _initializeHERESDK() async {
  // Needs to be called before accessing SDKOptions to load necessary libraries.
  SdkContext.init(IsolateOrigin.main);

  // Set your credentials for the HERE SDK.
  String accessKeyId = "WzUaMuIPmtGIaJ-DBu5lsw";
  String accessKeySecret = "s9sZvAdW1b5LMei9OHAklwNG_bvXtd1PI0I6C1ZZtbtl7_2x9hQrXLtdxEluRvthQ2uyUl8PCTncGg74qubp_Q";
  AuthenticationMode authenticationMode = AuthenticationMode.withKeySecret(accessKeyId, accessKeySecret);
  SDKOptions sdkOptions = SDKOptions.withAuthenticationMode(authenticationMode);

  try {
    await SDKNativeEngine.makeSharedInstance(sdkOptions);
  } on InstantiationException {
    throw Exception("Failed to initialize the HERE SDK.");
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class MapTapListener implements TapListener {
  final Function(Point2D) onTapCallback;
  
  MapTapListener(this.onTapCallback);
  
  @override
  void onTap(Point2D origin) {
    onTapCallback(origin);
  }
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  late final AppLifecycleListener _appLifecycleListener;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  HereMapController? _hereMapController;
  MapPolygon? _currentPolygon;
  List<MapPolygon> _clickedCircles = [];
  List<MapMarker> _mapMarkers = [];
  List<Widget> _herdWidgets = [];
  int _herdWidgetTestIndex = 0;
  final List<int> _herdWidgetCounts = [5, 10, 25, 50];
  final Random _random = Random();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HERE SDK for Flutter - Hello Map!',
      home: HereMap(onMapCreated: _onMapCreated),
    );
  }
  MapPolygon _createMapCircle() {
  double radiusInMeters = 300;
  GeoCircle geoCircle = GeoCircle(GeoCoordinates(52.54014, 13.37958), radiusInMeters);

  GeoPolygon geoPolygon = GeoPolygon.withGeoCircle(geoCircle);
  Color fillColor = Color.fromARGB(160, 0, 144, 138);
  MapPolygon mapPolygon = MapPolygon(geoPolygon, fillColor);

  return mapPolygon;
}

MapPolygon? _createPolygon({double scale = 1.0}) {
  List<GeoCoordinates> coordinates = [];
  // Note that a polygon requires a clockwise or counter-clockwise order of the coordinates.
  
  // Fixed point (top-left corner)
  double baseLat = 52.54014;
  double baseLon = 13.37958;
  
  // Define rectangle dimensions - only horizontal (longitude) scales
  double latDelta = -0.01; // Fixed vertical size (approximately 1km south)
  double lonDelta = 0.015 * scale; // Horizontal size scales with animation (approximately 1km east, scaled)
  
  // Create rectangle coordinates in clockwise order
  coordinates.add(GeoCoordinates(baseLat, baseLon)); // Top-left (fixed point)
  coordinates.add(GeoCoordinates(baseLat, baseLon + lonDelta)); // Top-right
  coordinates.add(GeoCoordinates(baseLat + latDelta, baseLon + lonDelta)); // Bottom-right
  coordinates.add(GeoCoordinates(baseLat + latDelta, baseLon)); // Bottom-left

  GeoPolygon geoPolygon;
  try {
    geoPolygon = GeoPolygon(coordinates);
  } on InstantiationException {
    // Less than three vertices.
    return null;
  }

  Color fillColor = Color.fromARGB(160, 0, 144, 138);
  MapPolygon mapPolygon = MapPolygon(geoPolygon, fillColor);

  return mapPolygon;
}
  MapPolygon _createClickCircle(GeoCoordinates coordinates) {
    double radiusInMeters = 150;
    GeoCircle geoCircle = GeoCircle(coordinates, radiusInMeters);

    GeoPolygon geoPolygon = GeoPolygon.withGeoCircle(geoCircle);
    Color fillColor = Color.fromARGB(160, 255, 100, 100); // Red color to distinguish from other shapes
    MapPolygon mapPolygon = MapPolygon(geoPolygon, fillColor);

    return mapPolygon;
  }

  void _onMapTapped(Point2D touchPoint) {
    if (_hereMapController != null) {
      GeoCoordinates? geoCoordinates = _hereMapController!.viewToGeoCoordinates(touchPoint);
      if (geoCoordinates != null) {
        // Log coordinates to console
        print('Clicked at: Latitude ${geoCoordinates.latitude}, Longitude ${geoCoordinates.longitude}');
        
        // Create and add circle at clicked location
        MapPolygon clickCircle = _createClickCircle(geoCoordinates);
        _clickedCircles.add(clickCircle);
        _hereMapController!.mapScene.addMapPolygon(clickCircle);
        
        // Cycle through different numbers of herd widgets on each tap
        int herdCount = _herdWidgetCounts[_herdWidgetTestIndex];
        _herdWidgetTestIndex = (_herdWidgetTestIndex + 1) % _herdWidgetCounts.length;
        
        print('Creating $herdCount herd widgets...');
        _createMultipleHerdWidgets(herdCount, radiusInKm: 3.0);
      }
    }
  }
  Future<Uint8List> _loadFileAsUint8List(String assetPathToFile) async {
  // The path refers to the assets directory as specified in pubspec.yaml.
  ByteData fileData = await rootBundle.load(assetPathToFile);
  return Uint8List.view(fileData.buffer);
}
  void _onMapCreated(HereMapController hereMapController) {
    _hereMapController = hereMapController;
    
    // The camera can be configured before or after a scene is loaded.
    const double distanceToEarthInMeters = 8000;
    MapMeasure mapMeasureZoom =
        MapMeasure(MapMeasureKind.distanceInMeters, distanceToEarthInMeters);
    hereMapController.camera.lookAtPointWithMeasure(
        GeoCoordinates(52.54014, 13.37958), mapMeasureZoom);

    // Load the map scene using a map scheme to render the map with.
    hereMapController.mapScene.loadSceneForMapScheme(MapScheme.hybridDay, (MapError? error) {
      if (error != null) {
        print('Map scene not loaded. MapError: ${error.toString()}');
      } else {
        // Start animation after map is loaded
        _updatePolygon();
        _animationController.repeat(reverse: true);
        // _hereMapController!.mapScene.addMapPolygon(_createMapCircle());
        
        // Set up tap gesture
        _hereMapController!.gestures.tapListener = MapTapListener(_onMapTapped);
      }
    });
    _loadImage();

    // Create multiple herd widgets with randomized numbers
    _createMultipleHerdWidgets(10, radiusInKm: 5.0);
  }
  Widget _createWidget(String label, Color backgroundColor) {
    return           _createHerdWidget(5); // Display number 5

  }

  Widget _createHerdWidget(int number) {
    return Container(
      width: 110,
      height: 46,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Speech bubble background
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/speech_bubble.svg',
              width: 110,
              height: 46,
              fit: BoxFit.contain,
              allowDrawingOutsideViewBox: true,
              matchTextDirection: false,
            ),
          ),
          // Cow icon
          Positioned(
            left: 16,
            top: 4,
            child: SvgPicture.asset(
              'assets/cow_icon.svg',
              width: 30,
              height: 24,
              fit: BoxFit.contain,
              allowDrawingOutsideViewBox: true,
              matchTextDirection: false,
            ),
          ),
          // Dynamic number
          Positioned(
            left: 47,
            top: 6,
            child: Text(
              number.toString(),
              style: TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          // Animated spinner
          Positioned(
            left: 76,
            top: 7,
            child: AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: SvgPicture.asset(
                    'assets/spinner_icon.svg',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    allowDrawingOutsideViewBox: true,
                    matchTextDirection: false,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
void _loadImage() async {
  // Create multiple markers for performance testing
  // You can change this number to test different marker counts
  int markerCount = 15000; // Start with 100 markers
  // _createMultipleMarkers(markerCount, radiusInKm: 60.0);
  
  // Optional: Add a single marker at the center for reference
  int imageWidth = 120;
  int imageHeight = 120;
  MapImage centerMapImage = MapImage.withFilePathAndWidthAndHeight("assets/ano.png", imageWidth, imageHeight);
  MapMarker centerMarker = MapMarker(GeoCoordinates(52.54014, 13.37958), centerMapImage);
  _hereMapController?.mapScene.addMapMarker(centerMarker);
  _mapMarkers.add(centerMarker);
}
  void _updatePolygon() {
    if (_hereMapController != null) {
      // Remove current polygon if it exists
      if (_currentPolygon != null) {
        _hereMapController!.mapScene.removeMapPolygon(_currentPolygon!);
      }
      
      // Create new polygon with current scale
      _currentPolygon = _createPolygon(scale: _scaleAnimation.value);
      if (_currentPolygon != null) {
        _hereMapController!.mapScene.addMapPolygon(_currentPolygon!);
      }
    }
  }
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller (2 seconds for full cycle)
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Initialize rotation animation controller (2 seconds for full rotation)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Create oscillating animation (1.0 to 2.0 and back)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Create rotation animation (0 to 2π radians)
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // Listen to animation changes and update polygon
    _scaleAnimation.addListener(_updatePolygon);
    
    // Start rotation animation
    _rotationController.repeat();
    
    _appLifecycleListener = AppLifecycleListener(
      onDetach: () =>
      // Sometimes Flutter may not reliably call dispose(),
      // therefore it is recommended to dispose the HERE SDK
      // also when the AppLifecycleListener is detached.
      // See more details: https://github.com/flutter/flutter/issues/40940
      { print('AppLifecycleListener detached.'), _disposeHERESDK() },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    _disposeHERESDK();
    super.dispose();
  }

  void _disposeHERESDK() async {
    // Clean up clicked circles
    if (_hereMapController != null) {
      for (MapPolygon circle in _clickedCircles) {
        _hereMapController!.mapScene.removeMapPolygon(circle);
      }
      _clickedCircles.clear();
      
      // Clean up markers
      _clearAllMarkers();
      
      // Clean up herd widgets
      _clearAllHerdWidgets();
    }
    
    // Free HERE SDK resources before the application shuts down.
    await SDKNativeEngine.sharedInstance?.dispose();
    SdkContext.release();
    _appLifecycleListener.dispose();
  }
  
  GeoCoordinates _generateRandomCoordinate(GeoCoordinates center, double maxRadiusInKm) {
    // Convert km to approximate degrees (rough approximation for Berlin area)
    double maxLatDelta = maxRadiusInKm / 111.0; // 1 degree lat ≈ 111 km
    double maxLonDelta = maxRadiusInKm / (111.0 * cos(center.latitude * pi / 180)); // Adjust for latitude
    
    // Generate random deltas within the radius
    double latDelta = (_random.nextDouble() - 0.5) * 2 * maxLatDelta;
    double lonDelta = (_random.nextDouble() - 0.5) * 2 * maxLonDelta;
    
    return GeoCoordinates(center.latitude + latDelta, center.longitude + lonDelta);
  }
  
  void _createMultipleMarkers(int count, {double radiusInKm = 2.0}) {
    print('Creating $count markers within ${radiusInKm}km radius...');
    
    // Clear existing markers
    _clearAllMarkers();
    
    // Central coordinate (Berlin)
    GeoCoordinates center = GeoCoordinates(52.54014, 13.37958);
    
    // Create markers
    for (int i = 0; i < count; i++) {
      GeoCoordinates randomCoord = _generateRandomCoordinate(center, radiusInKm);
      
      int imageWidth = 60;
      int imageHeight = 60;
      MapImage mapImage = MapImage.withFilePathAndWidthAndHeight("assets/ano.png", imageWidth, imageHeight);
      MapMarker mapMarker = MapMarker(randomCoord, mapImage);
      
      _mapMarkers.add(mapMarker);
      _hereMapController?.mapScene.addMapMarker(mapMarker);
    }
    
    print('Successfully created ${_mapMarkers.length} markers');
  }
  
  void _clearAllMarkers() {
    if (_hereMapController != null) {
      for (MapMarker marker in _mapMarkers) {
        _hereMapController!.mapScene.removeMapMarker(marker);
      }
      _mapMarkers.clear();
    }
  }
  
  void _createMultipleHerdWidgets(int count, {double radiusInKm = 2.0}) {
    print('Creating $count herd widgets within ${radiusInKm}km radius...');
    
    // Clear existing herd widgets
    _clearAllHerdWidgets();
    
    // Central coordinate (Berlin)
    GeoCoordinates center = GeoCoordinates(52.54014, 13.37958);
    
    // Create herd widgets
    for (int i = 0; i < count; i++) {
      GeoCoordinates randomCoord = _generateRandomCoordinate(center, radiusInKm);
      
      // Generate random number between 1 and 99
      int randomNumber = _random.nextInt(99) + 1;
      
      Widget herdWidget = _createHerdWidget(randomNumber);
      
      _hereMapController?.pinWidget(herdWidget, randomCoord);
      _herdWidgets.add(herdWidget);
    }
    
    print('Successfully created ${_herdWidgets.length} herd widgets');
  }
  
  void _clearAllHerdWidgets() {
    // Note: HERE SDK doesn't provide a direct way to remove pinned widgets
    // In a real implementation, you'd need to keep track of the pinned widgets
    // and manage them appropriately. For now, we'll clear our tracking list.
    _herdWidgets.clear();
  }
  
  // Performance testing helper functions
  void _test10Markers() => _createMultipleMarkers(10);
  void _test50Markers() => _createMultipleMarkers(50);
  void _test100Markers() => _createMultipleMarkers(100);
  void _test500Markers() => _createMultipleMarkers(500);
  void _test1000Markers() => _createMultipleMarkers(1000);
  void _test10HerdWidgets() => _createMultipleHerdWidgets(10);
  void _test50HerdWidgets() => _createMultipleHerdWidgets(50);
  void _test100HerdWidgets() => _createMultipleHerdWidgets(100);
}
