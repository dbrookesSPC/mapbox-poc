import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:maps_poc/basicMap.dart';
import 'package:maps_poc/page.dart';
import 'package:maps_poc/pages/markers/many_markers.bloc.dart';
import 'package:maps_poc/pages/markers/many_markers.events.dart';
import 'package:maps_poc/pages/markers/many_markers.state.dart';
import 'package:maps_poc/pages/markers/coordinate_bound_widget.dart';
import 'animated_herd_widget.dart';

class ManyMarkers extends StatefulWidget implements PocPage {
  const ManyMarkers({super.key});

  @override
  final Widget leading = const Icon(Icons.location_on_outlined);
  @override
  final String title = 'Many Markers';
  @override
  final String subtitle = 'Animated herd widgets with SVG assets';

  @override
  State<StatefulWidget> createState() => _ManyMarkersMap();
}

class _ManyMarkersMap extends SimpleMapState {
  late final ManyMarkersBloc _markersBloc;
  final List<MarkerData> _overlayMarkers = [];
  bool _useOverlayMode = true; // Toggle between overlay widgets and static images

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
        
        print('Generated marker $i at: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}');
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

  void _generateStaticMarkers(int count) async {
    if (mapboxMap == null) return;
    
    try {
      final currentCamera = await mapboxMap!.getCameraState();
      _markersBloc.add(GenerateMarkers(
        count: count,
        centerCoordinate: currentCamera.center,
        zoom: currentCamera.zoom,
      ));
    } catch (e) {
      // Fallback without camera info
      _markersBloc.add(GenerateMarkers(count: count));
    }
  }

  void _clearMarkers() {
    if (_useOverlayMode) {
      setState(() {
        _overlayMarkers.clear();
      });
    } else {
      _markersBloc.add(ClearMarkers());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _markersBloc,
      child: Stack(
        children: [
          super.build(context), // MapboxMap
          
          // Coordinate-bound animated widgets (only in overlay mode)
          if (_useOverlayMode && mapboxMap != null)
            ...(_overlayMarkers.map((markerData) => 
              CoordinateBoundWidget(
                mapboxMap: mapboxMap!,
                latitude: markerData.latitude,
                longitude: markerData.longitude,
                offset: const Offset(-55, -23), // Center the 110x46 widget (110/2 = 55, 46/2 = 23)
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
                      _useOverlayMode ? 'Animated Widget Overlays' : 'Static Image Markers',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    
                    // Mode Toggle
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _useOverlayMode = true;
                                _overlayMarkers.clear();
                              });
                              _markersBloc.add(ClearMarkers());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _useOverlayMode ? Colors.blue : null,
                              foregroundColor: _useOverlayMode ? Colors.white : null,
                            ),
                            child: const Text('Overlay Mode'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _useOverlayMode = false;
                                _overlayMarkers.clear();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_useOverlayMode ? Colors.blue : null,
                              foregroundColor: !_useOverlayMode ? Colors.white : null,
                            ),
                            child: const Text('Static Mode'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Display current count and buttons
                    if (_useOverlayMode) ...[
                      // Overlay mode UI
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
                        // Generation buttons for overlay mode
                        _buildGenerationButtons(true),
                      ],
                    ] else ...[
                      // Static mode UI with BlocBuilder
                      BlocBuilder<ManyMarkersBloc, ManyMarkersState>(
                        builder: (context, state) {
                          if (state is ManyMarkersLoaded) {
                            return Column(
                              children: [
                                Text(
                                  '${state.markerCount} static markers displayed',
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
                              ],
                            );
                          }
                          
                          if (state is ManyMarkersGenerating) {
                            return Column(
                              children: [
                                Text(
                                  'Generating: ${state.generatedCount}/${state.totalCount}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: state.generatedCount / state.totalCount,
                                ),
                              ],
                            );
                          }
                          
                          if (state is ManyMarkersLoading) {
                            return const Column(
                              children: [
                                Text('Loading...'),
                                SizedBox(height: 8),
                                CircularProgressIndicator(),
                              ],
                            );
                          }
                          
                          // Default state - show generation buttons
                          return _buildGenerationButtons(false);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

       

          // Status Messages
          BlocListener<ManyMarkersBloc, ManyMarkersState>(
            listener: (context, state) {
              if (state is ManyMarkersLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${state.markerCount} static herd markers generated'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is ManyMarkersError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationButtons(bool isOverlayMode) {
    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => isOverlayMode 
                    ? _generateOverlayMarkers(10) 
                    : _generateStaticMarkers(10),
                child: const Text('10 Herds'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => isOverlayMode 
                    ? _generateOverlayMarkers(50) 
                    : _generateStaticMarkers(50),
                child: const Text('50 Herds'),
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
                onPressed: () => isOverlayMode 
                    ? _generateOverlayMarkers(100) 
                    : _generateStaticMarkers(100),
                child: const Text('100 Herds'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => isOverlayMode 
                    ? _generateOverlayMarkers(200) 
                    : _generateStaticMarkers(500),
                child: Text(isOverlayMode ? '200 Herds' : '500 Herds'),
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
          'Mode: ${_useOverlayMode ? "Live animated widget" : "Static image"}'
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
    
    // Initialize the annotation manager for static markers
    if (pointAnnotationManager != null) {
      _markersBloc.add(InitializeAnnotationManager(
        annotationManager: pointAnnotationManager!,
      ));
    }
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