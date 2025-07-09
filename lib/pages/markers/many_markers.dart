import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:maps_poc/basicMap.dart';
import 'package:maps_poc/page.dart';
import 'package:maps_poc/pages/markers/many_markers.bloc.dart';
import 'package:maps_poc/pages/markers/many_markers.events.dart';
import 'package:maps_poc/pages/markers/many_markers.state.dart';
import 'coordinate_bound_widget.dart';
import 'animated_herd_widget.dart';

class ManyMarkers extends StatefulWidget implements PocPage {
  const ManyMarkers({super.key});

  @override
  final Widget leading = const Icon(Icons.location_on_outlined);
  @override
  final String title = 'Performance Test';
  @override
  final String subtitle = 'Test 10-100 mixed elements, 1K widgets, or 4K elements';

  @override
  State<StatefulWidget> createState() => _ManyMarkersMap();
}

class _ManyMarkersMap extends SimpleMapState {
  late final ManyMarkersBloc _markersBloc;
  final List<MarkerData> _overlayMarkers = [];

  @override
  void initState() {
    super.initState();
    _markersBloc = ManyMarkersBloc();
  }

  @override
  void dispose() {
    _markersBloc.close();
    super.dispose();
  }

  void _generateOverlayMarkers(int count) async {
    if (mapboxMap == null) return;
    
    final Random random = Random();
    _overlayMarkers.clear();

    try {
      // Get current camera state to determine where to place markers
      final currentCamera = await mapboxMap!.getCameraState();
      final centerLat = currentCamera.center.coordinates.lat;
      final centerLng = currentCamera.center.coordinates.lng;
      final currentZoom = currentCamera.zoom;
      
      // Calculate spread based on zoom level
      // Higher zoom = smaller spread, Lower zoom = larger spread
      double spread;
      if (currentZoom >= 15) {
        spread = 0.01; // Very tight area for high zoom
      } else if (currentZoom >= 12) {
        spread = 0.05; // Medium area
      } else if (currentZoom >= 10) {
        spread = 0.1; // Wider area
      } else {
        spread = 0.2; // Very wide area for low zoom
      }
      
      print('Generating markers around camera center: $centerLat, $centerLng (zoom: $currentZoom, spread: $spread)');
      
      final double minLat = centerLat - spread;
      final double maxLat = centerLat + spread;
      final double minLng = centerLng - spread;
      final double maxLng = centerLng + spread;

      for (int i = 0; i < count; i++) {
        final double lat = minLat + (maxLat - minLat) * random.nextDouble();
        final double lng = minLng + (maxLng - minLng) * random.nextDouble();
        final int herdSize = 1 + random.nextInt(99);

        _overlayMarkers.add(MarkerData(
          id: i,
          latitude: lat,
          longitude: lng,
          herdSize: herdSize,
        ));
      }

      setState(() {});
      
    } catch (e) {
      print('Error getting camera state: $e');
      // Fallback to Berlin if camera state fails
      _generateOverlayMarkersAroundBerlin(count);
    }
  }

  void _generateOverlayMarkersAroundBerlin(int count) {
    // Fallback method for Berlin area
    final Random random = Random();
    _overlayMarkers.clear();

    const double centerLat = 52.5;
    const double centerLng = 13.4;
    const double spread = 0.1;
    
    const double minLat = centerLat - spread;
    const double maxLat = centerLat + spread;
    const double minLng = centerLng - spread;
    const double maxLng = centerLng + spread;

    for (int i = 0; i < count; i++) {
      final double lat = minLat + (maxLat - minLat) * random.nextDouble();
      final double lng = minLng + (maxLng - minLng) * random.nextDouble();
      final int herdSize = 1 + random.nextInt(99);

      _overlayMarkers.add(MarkerData(
        id: i,
        latitude: lat,
        longitude: lng,
        herdSize: herdSize,
      ));
    }

    setState(() {});
  }

  void _clearMarkers() async {
    // Clear all annotation types
    await pointAnnotationManager?.deleteAll();
    await polygonAnnotationManager?.deleteAll();
    await polylineAnnotationManager?.deleteAll();
    
    setState(() {
      _overlayMarkers.clear();
    });
  }

  Future<void> _loadAndGenerateElements({bool useLargeFile = false, bool use1000File = false}) async {
    if (mapboxMap == null) return;

    String fileName;
    if (use1000File) {
      fileName = 'assets/test_elements_1000.json';
    } else {
      fileName = useLargeFile ? 'assets/test_elements_large.json' : 'assets/test_elements.json';
    }
    
    String data = await DefaultAssetBundle.of(context).loadString(fileName);
    final jsonData = json.decode(data);
    
    // Adjust camera based on the number of elements
    if (use1000File) {
      await _adjustCameraForElementCount(4050); // 1000 polygons + 2000 markers + 50 widgets + 1000 lines
    } else if (useLargeFile) {
      await _adjustCameraForElementCount(220); // approximately 220 total elements
    } else {
      await _adjustCameraForElementCount(40); // 10 of each type
    }
    
    // Add polygons as polygon layers
    await _addPolygons(jsonData['polygons']);
    
    // Add markers as point annotations
    await _addMarkers(jsonData['customMarkers']);
    
    // Add widgets as overlay markers
    await _addWidgets(jsonData['pinnedWidgets']);
    
    // Add lines as line layers
    await _addLines(jsonData['lines']);
    
    // Show completion message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded ${jsonData['polygons'].length} polygons, ${jsonData['customMarkers'].length} markers, ${jsonData['pinnedWidgets'].length} widgets, ${jsonData['lines'].length} lines'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _adjustCameraForElementCount(int totalElements) async {
    if (mapboxMap == null) return;
    
    double zoom;
    Point center;
    
    if (totalElements >= 4000) {
      zoom = 8.0; // Very wide view for 4000+ elements
      center = Point(coordinates: Position(13.405, 52.52)); // Berlin center
    } else if (totalElements >= 1000) {
      zoom = 9.0; // Wide view for 1000+ elements
      center = Point(coordinates: Position(13.405, 52.52));
    } else if (totalElements >= 100) {
      zoom = 10.0; // Moderate view for 100+ elements
      center = Point(coordinates: Position(13.381, 52.542));
    } else {
      zoom = 12.0; // Closer view for smaller counts
      center = Point(coordinates: Position(13.381, 52.542));
    }
    
    await mapboxMap!.flyTo(
      CameraOptions(
        center: center,
        zoom: zoom,
        bearing: 0.0,
        pitch: 0.0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  Future<void> _addPolygons(List<dynamic> polygons) async {
    if (polygonAnnotationManager == null) return;
    
    List<PolygonAnnotationOptions> polygonAnnotations = [];
    
    for (var polygon in polygons) {
      final points = polygon['points'] as List<dynamic>;
      
      // Convert points to Position objects for Mapbox
      List<Position> positions = points.map<Position>((point) {
        return Position(point[1], point[0]); // lng, lat
      }).toList();
      
      // Close the polygon by adding the first point at the end if not already closed
      if (positions.isNotEmpty && positions.first != positions.last) {
        positions.add(positions.first);
      }
      
      polygonAnnotations.add(
        PolygonAnnotationOptions(
          geometry: Polygon(coordinates: [positions]),
          fillColor: Colors.blue.withOpacity(0.3).value,
          fillOutlineColor: Colors.blue.value,
        ),
      );
    }
    
    await polygonAnnotationManager!.createMulti(polygonAnnotations);
    print('Added ${polygons.length} polygons');
  }

  Future<void> _addMarkers(List<dynamic> markers) async {
    if (pointAnnotationManager == null) return;
    
    List<PointAnnotationOptions> pointAnnotations = [];
    
    // Load icon images as bytes
    Map<String, Uint8List> iconCache = {};
    
    for (var marker in markers) {
      final coords = marker['coordinates'];
      final markerType = marker['type'] ?? 'restaurant';
      
      // Get icon path based on marker type
      String iconPath = _getIconPath(markerType);
      
      // Load icon bytes (cache to avoid loading same icon multiple times)
      if (!iconCache.containsKey(iconPath)) {
        final ByteData data = await rootBundle.load(iconPath);
        iconCache[iconPath] = data.buffer.asUint8List();
      }
      
      pointAnnotations.add(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(coords[1], coords[0])), // lng, lat
          image: iconCache[iconPath],
          iconSize: 0.5, // Scale down the icon
        ),
      );
    }
    
    await pointAnnotationManager!.createMulti(pointAnnotations);
    print('Added ${markers.length} markers with custom icons');
  }
  
  String _getIconPath(String markerType) {
    // Map marker types to available icons
    switch (markerType) {
      case 'restaurant':
        return 'assets/icons_png/restaurant.png';
      case 'hospital':
        return 'assets/icons_png/hospital.png';
      case 'school':
        return 'assets/icons_png/school.png';
      case 'park':
        return 'assets/icons_png/park.png';
      case 'bank':
        return 'assets/icons_png/bank.png';
      case 'shop':
      case 'gas_station':
      case 'pharmacy':
      case 'cafe':
      case 'hotel':
      default:
        return 'assets/icons_png/restaurant.png'; // Default fallback
    }
  }

  Future<void> _addWidgets(List<dynamic> widgets) async {
    // Add widgets as overlay markers (like the existing herd widgets)
    final Random random = Random();
    
    for (int i = 0; i < widgets.length; i++) {
      final widget = widgets[i];
      final coords = widget['coordinates'];
      
      _overlayMarkers.add(MarkerData(
        id: i + 1000, // Offset to avoid conflicts
        latitude: coords[0],
        longitude: coords[1],
        herdSize: 1 + random.nextInt(99),
      ));
    }
    
    setState(() {});
    print('Added ${widgets.length} overlay widgets');
  }

  Future<void> _addLines(List<dynamic> lines) async {
    if (polylineAnnotationManager == null) return;
    
    List<PolylineAnnotationOptions> polylineAnnotations = [];
    
    for (var line in lines) {
      final start = line['start'];
      final end = line['end'];
      
      polylineAnnotations.add(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: [
            Position(start[1], start[0]), // lng, lat
            Position(end[1], end[0]),     // lng, lat
          ]),
          lineColor: Colors.red.value,
          lineWidth: 2.0,
        ),
      );
    }
    
    await polylineAnnotationManager!.createMulti(polylineAnnotations);
    print('Added ${lines.length} lines');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _markersBloc,
      child: Stack(
        children: [
          super.build(context), // MapboxMap
          
          // Coordinate-bound animated widgets
          if (mapboxMap != null)
            ...(_overlayMarkers.map((markerData) => 
              CoordinateBoundWidget(
                mapboxMap: mapboxMap!,
                latitude: markerData.latitude,
                longitude: markerData.longitude,
                offset: const Offset(-55, -23), // Center the 110x46 widget
                child: AnimatedHerdWidget(
                  herdSize: markerData.herdSize,
                  onTap: () => _onMarkerTap(markerData),
                ),
              )
            ).toList()),
          
          // Control Panel
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Performance Test - Mapbox',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    
                    // Display current count and buttons
                    if (_overlayMarkers.isNotEmpty) ...[
                      Text(
                        '4000 elements displayed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _clearMarkers,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Clear All'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Performance test buttons
                      _buildPerformanceTestButtons(),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // // Feature info
          // Positioned(
          //   top: 200,
          //   left: 16,
          //   right: 16,
          //   child: Card(
          //     child: Padding(
          //       padding: const EdgeInsets.all(12.0),
          //       child: Column(
          //         mainAxisSize: MainAxisSize.min,
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Text(
          //             'Features:',
          //             style: Theme.of(context).textTheme.titleSmall?.copyWith(
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //           const SizedBox(height: 4),
          //           Text('• Live SVG rendering with animations', style: Theme.of(context).textTheme.bodySmall),
          //           Text('• Rotating spinner animations', style: Theme.of(context).textTheme.bodySmall),
          //           Text('• Coordinate-bound positioning', style: Theme.of(context).textTheme.bodySmall),
          //           Text('• Full tap/gesture support', style: Theme.of(context).textTheme.bodySmall),
          //           Text('• Automatic visibility culling', style: Theme.of(context).textTheme.bodySmall),
          //           Text('• 60 FPS smooth tracking', style: Theme.of(context).textTheme.bodySmall),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTestButtons() {
    return Column(
      children: [
        // First row - Element tests
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _loadAndGenerateElements(useLargeFile: false),
                icon: const Icon(Icons.location_on),
                label: const Text('10 Elements'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _loadAndGenerateElements(useLargeFile: true),
                icon: const Icon(Icons.location_on),
                label: const Text('100 Elements'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Second row - Widget and major test
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _generateOverlayMarkers(1000),
                icon: const Icon(Icons.widgets),
                label: const Text('1K Widgets'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _loadAndGenerateElements(use1000File: true),
                icon: const Icon(Icons.grid_view),
                label: const Text('4K Elements'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onMarkerTap(MarkerData markerData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Herd ${markerData.herdSize}'),
        content: Text(
          'Herd ID: ${markerData.id}\n'
          'Size: ${markerData.herdSize} animals\n'
          'Location: ${markerData.latitude.toStringAsFixed(4)}, ${markerData.longitude.toStringAsFixed(4)}\n'
          'Type: Live animated widget'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  onMapCreated() async {
    super.onMapCreated();
    print("Many Markers map created and ready");
  }
}

class MarkerData {
  final int id;
  final double latitude;
  final double longitude;
  final int herdSize;

  MarkerData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.herdSize,
  });
}