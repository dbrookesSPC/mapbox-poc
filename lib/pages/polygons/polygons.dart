import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/mapview.dart';
import 'package:maps_poc/basicMap.dart';
import 'package:maps_poc/page.dart';
import 'package:maps_poc/pages/polygons/polygons.bloc.dart';
import 'package:maps_poc/pages/polygons/polygons.events.dart' as events;
import 'package:maps_poc/pages/polygons/polygons.state.dart';

class Polygons extends StatefulWidget implements PocPage {
  const Polygons({super.key});

  @override
  final Widget leading = const Icon(Icons.format_shapes_outlined);
  @override
  final String title = 'Polygons';
  @override
  final String subtitle = 'Draw polygons on the map';

  @override
  State<StatefulWidget> createState() => _PolygonMap();
}

class _PolygonMap extends SimpleMapState {
  late final PolygonsBloc _polygonsBloc;

  @override
  void initState() {
    super.initState();
    _polygonsBloc = PolygonsBloc();
  }

  @override
  void dispose() {
    _polygonsBloc.close();
    super.dispose();
  }

  void _clearAll() {
    _polygonsBloc.add(events.ClearAll(
      hereMapController: hereMapController,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _polygonsBloc,
      child: Stack(
        children: [
          super.build(context), // HereMap
          
          // Instructions Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Instructions:',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Tap to place points (minimum 3)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '• Long press to create polygon',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '• Tap polygon to see details',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _clearAll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status Card
          BlocBuilder<PolygonsBloc, PolygonsState>(
            builder: (context, state) {
              if (state is PolygonsReady || state is PointAdded || state is PolygonCreated) {
                final tapPositions = state is PolygonsReady 
                    ? state.tapPositions
                    : state is PointAdded 
                        ? state.tapPositions
                        : state is PolygonCreated
                            ? state.tapPositions
                            : <GeoCoordinates>[];

                final polygonFeatures = state is PolygonsReady 
                    ? state.polygonFeatures
                    : state is PointAdded 
                        ? state.polygonFeatures
                        : state is PolygonCreated
                            ? state.polygonFeatures
                            : <PolygonData>[];

                if (tapPositions.isNotEmpty || polygonFeatures.isNotEmpty) {
                  return Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (tapPositions.isNotEmpty)
                              Text(
                                'Points placed: ${tapPositions.length}${tapPositions.length >= 3 ? ' - Ready to create polygon!' : ' - Need ${3 - tapPositions.length} more'}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (polygonFeatures.isNotEmpty)
                              Text(
                                'Polygons created: ${polygonFeatures.length}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),

          // Status Messages
          BlocListener<PolygonsBloc, PolygonsState>(
            listener: (context, state) {
              if (state is PointAdded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Point added (${state.tapPositions.length}/${state.tapPositions.length >= 3 ? "Ready" : "3 minimum"})',
                    ),
                    duration: const Duration(seconds: 1),
                    backgroundColor: Colors.blue,
                  ),
                );
              } else if (state is PolygonCreated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Polygon "${state.polygonName}" created!'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is PolygonTapped) {
                final name = state.tappedPolygon.name;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Polygon Details'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name: $name'),
                        Text('ID: ${state.tappedPolygon.id}'),
                        Text('Points: ${state.tappedPolygon.coordinates.length}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              } else if (state is PolygonsCleared) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All polygons and points cleared'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else if (state is PolygonsError) {
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

          // Loading Indicator
          BlocBuilder<PolygonsBloc, PolygonsState>(
            builder: (context, state) {
              if (state is PolygonsLoading) {
                return const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  @override
  onMapCreated() async {
    super.onMapCreated();
    
    // Initialize polygons once the HERE map controller is ready
    if (hereMapController != null) {
      _polygonsBloc.add(events.InitializePolygons(
        hereMapController: hereMapController!,
      ));
      
      // Set up tap gesture listener
      hereMapController!.gestures.tapListener = MapTapListener((geoCoordinates) {
        if (geoCoordinates != null) {
          onTapListener(geoCoordinates);
        }
      }, hereMapController);

      // Set up long tap gesture listener
      hereMapController!.gestures.longPressListener = PolygonMapLongPressListener((geoCoordinates) {
        if (geoCoordinates != null) {
          onLongTapListener(geoCoordinates);
        }
      }, hereMapController);
    }
  }

  @override
  Future<void> onTapListener(GeoCoordinates? coordinates) async {
    // Handle tap events through the BLoC to add points
    if (coordinates != null && hereMapController != null) {
      _polygonsBloc.add(events.AddPoint(
        lng: coordinates.longitude,
        lat: coordinates.latitude,
        hereMapController: hereMapController!,
      ));
    }
  }

  @override
  Future<void> onLongTapListener(GeoCoordinates? coordinates) async {
    // Handle long tap to create polygon
    if (hereMapController != null) {
      _polygonsBloc.add(events.CreatePolygon(
        hereMapController: hereMapController!,
      ));
    }
  }
}

// Helper class for long press handling - moved outside the class
class PolygonMapLongPressListener implements LongPressListener {
  final Function(GeoCoordinates?) onLongPressCallback;
  final HereMapController? mapController;
  
  PolygonMapLongPressListener(this.onLongPressCallback, this.mapController);
  
  @override
  void onLongPress(GestureState gestureState, Point2D origin) {
    GeoCoordinates? geoCoordinates = mapController?.viewToGeoCoordinates(origin);
    onLongPressCallback(geoCoordinates);
  }
}