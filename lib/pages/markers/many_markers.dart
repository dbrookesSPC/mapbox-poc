import 'dart:math';
import 'package:flutter/material.dart';
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
  final String title = 'Many Markers';
  @override
  final String subtitle = 'Animated herd widgets bound to coordinates';

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

  void _clearMarkers() {
    setState(() {
      _overlayMarkers.clear();
    });
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
                      'Animated Coordinate-Bound Widgets',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    
                    // Display current count and buttons
                    if (_overlayMarkers.isNotEmpty) ...[
                      Text(
                        '${_overlayMarkers.length} animated widgets displayed',
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
                      // Generation buttons
                      _buildGenerationButtons(),
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

  Widget _buildGenerationButtons() {
    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _generateOverlayMarkers(10),
                child: const Text('10 Herds'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _generateOverlayMarkers(25),
                child: const Text('25 Herds'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Second row
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _generateOverlayMarkers(50),
                child: const Text('50 Herds'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _generateOverlayMarkers(100),
                child: const Text('100 Herds'),
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