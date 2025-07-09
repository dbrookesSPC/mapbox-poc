import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:maps_poc/basicMap.dart';
import 'package:maps_poc/page.dart';
import 'package:maps_poc/pages/markers/many_markers.bloc.dart';
import 'package:maps_poc/pages/markers/many_markers.events.dart';
import 'package:maps_poc/pages/markers/many_markers.state.dart';
import 'package:maps_poc/widgets/fps_counter.dart';

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

class _ManyMarkersMap extends SimpleMapState with TickerProviderStateMixin {
  late final ManyMarkersBloc _markersBloc;

  @override
  void initState() {
    super.initState();
    _markersBloc = ManyMarkersBloc();
    _markersBloc.initializeAnimationController(this);
  }

  @override
  void dispose() {
    _markersBloc.close();
    super.dispose();
  }

Future<void> _loadAndGenerateElements({bool useLargeFile = false, bool use1000File = false}) async {
    if (hereMapController == null) return;

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
      _adjustCameraForElementCount(4050); // 1000 polygons + 2000 markers + 50 widgets + 1000 lines
    } else if (useLargeFile) {
      _adjustCameraForElementCount(220); // approximately 220 total elements
    } else {
      _adjustCameraForElementCount(40); // 10 of each type
    }

    for (var polygon in jsonData['polygons']) {
      _markersBloc.add(AddPolygon(
        polygon['points'].map<GeoCoordinates>((point) => GeoCoordinates(point[0], point[1])).toList(),
        hereMapController!
      ));
    }

    for (var marker in jsonData['customMarkers']) {
      _markersBloc.add(AddMarker(
        GeoCoordinates(marker['coordinates'][0], marker['coordinates'][1]),
        hereMapController!,
        markerType: marker['type']
      ));
    }

    for (var widget in jsonData['pinnedWidgets']) {
      _markersBloc.add(AddWidget(
        GeoCoordinates(widget['coordinates'][0], widget['coordinates'][1]),
        hereMapController!
      ));
    }

    for (var line in jsonData['lines']) {
      _markersBloc.add(AddLine(
        GeoCoordinates(line['start'][0], line['start'][1]),
        GeoCoordinates(line['end'][0], line['end'][1]),
        hereMapController!
      ));
    }

    // Emit the loaded state with counts
    _markersBloc.add(LoadJSONElementsComplete(
      polygonCount: jsonData['polygons'].length,
      markerCount: jsonData['customMarkers'].length,
      widgetCount: jsonData['pinnedWidgets'].length,
      lineCount: jsonData['lines'].length,
    ));
  }

  void _generateHerdWidgets() {
    if (hereMapController == null) return;
    
    // Use current map center or default center
    final centerLat = defaultCenter.latitude;
    final centerLng = defaultCenter.longitude;
    
    _markersBloc.add(GenerateHerdWidgets(
      centerLng: centerLng,
      centerLat: centerLat,
      hereMapController: hereMapController!,
    ));
  }

  void _clearMarkers() {
    _markersBloc.add(ClearMarkers(hereMapController: hereMapController));
  }

  void _adjustCameraForElementCount(int totalElements) {
    if (hereMapController == null) return;
    
    // Calculate appropriate zoom level based on element count
    double zoomDistance;
    GeoCoordinates center;
    
    if (totalElements >= 4000) {
      // For 4000+ elements, zoom out very significantly
      zoomDistance = 40000.0; // 40km view
      center = GeoCoordinates(52.52000, 13.40500); // Berlin center
    } else if (totalElements >= 1000) {
      // For 1000+ elements, zoom out significantly
      zoomDistance = 30000.0; // 30km view
      center = GeoCoordinates(52.52000, 13.40500); // Berlin center
    } else if (totalElements >= 100) {
      // For 100+ elements, moderate zoom
      zoomDistance = 15000.0; // 15km view
      center = GeoCoordinates(52.54200, 13.38100); // Berlin area
    } else {
      // For smaller element counts, closer zoom
      zoomDistance = 8000.0; // 8km view
      center = GeoCoordinates(52.54200, 13.38100); // Berlin area
    }
    
    MapMeasure mapMeasureZoom = MapMeasure(MapMeasureKind.distanceInMeters, zoomDistance);
    hereMapController!.camera.lookAtPointWithMeasure(center, mapMeasureZoom);
  }

  @override
  Widget build(BuildContext context) {
    return FPSCounter(
      showFPS: true,
      child: BlocProvider.value(
        value: _markersBloc,
        child: Stack(
          children: [
            super.build(context), // HereMap
          
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Performance Test',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              BlocBuilder<ManyMarkersBloc, ManyMarkersState>(
                                builder: (context, state) {
                                  if (state is ManyMarkersLoaded) {
                                    return Text(
                                      '${state.markerCount} ${state.type} displayed',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    );
                                  }
                                  return Text(
                                    'Choose test type below',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        BlocBuilder<ManyMarkersBloc, ManyMarkersState>(
                          builder: (context, state) {
                            final isLoading = state is ManyMarkersLoading || 
                                            state is ManyMarkersGenerating;
                            
                            return ElevatedButton(
                              onPressed: isLoading ? null : _clearMarkers,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Clear'),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<ManyMarkersBloc, ManyMarkersState>(
                      builder: (context, state) {
                        final isLoading = state is ManyMarkersLoading || 
                                        state is ManyMarkersGenerating;
                        
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isLoading ? null : () => _loadAndGenerateElements(useLargeFile: false),
                                    icon: isLoading && state is ManyMarkersGenerating && state.type == "markers"
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.location_on),
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
                                    onPressed: isLoading ? null : () => _loadAndGenerateElements(useLargeFile: true),
                                    icon: isLoading && state is ManyMarkersGenerating && state.type == "markers"
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.location_on),
                                    label: const Text('100 Elements\n(10 widgets)'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isLoading ? null : _generateHerdWidgets,
                                    icon: isLoading && state is ManyMarkersGenerating && state.type == "widgets"
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.widgets),
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
                                    onPressed: isLoading ? null : () => _loadAndGenerateElements(use1000File: true),
                                    icon: isLoading && state is ManyMarkersGenerating && state.type == "markers"
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.map_outlined),
                                    label: const Text('4K Elements\n(50 widgets)'),
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
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Progress Indicator
          BlocBuilder<ManyMarkersBloc, ManyMarkersState>(
            builder: (context, state) {
              if (state is ManyMarkersGenerating) {
                final progress = state.generatedCount / state.totalCount;
                return Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Generating ${state.type}...',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: progress),
                          const SizedBox(height: 4),
                          Text(
                            '${state.generatedCount} / ${state.totalCount} (${(progress * 100).toInt()}%)',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Performance Info Card
          BlocBuilder<ManyMarkersBloc, ManyMarkersState>(
            builder: (context, state) {
              if (state is ManyMarkersLoaded) {
                return Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.speed, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Performance Test Complete',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${state.markerCount} ${state.type} rendered using HERE SDK',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Zoom and pan to test performance',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else if (state is ManyMarkersElementsLoaded) {
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
                          Row(
                            children: [
                              Icon(Icons.map, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'JSON Elements Loaded',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${state.polygonCount} polygons, ${state.markerCount} markers, ${state.widgetCount} widgets, ${state.lineCount} lines',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Rendered using HERE SDK',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Status Messages
          BlocListener<ManyMarkersBloc, ManyMarkersState>(
            listener: (context, state) {
              if (state is ManyMarkersLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${state.markerCount} ${state.type} generated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is ManyMarkersElementsLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('JSON elements loaded: ${state.polygonCount + state.markerCount + state.widgetCount + state.lineCount} total'),
                    backgroundColor: Colors.blue,
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
      ),
    );
  }

  @override
  onMapCreated() async {
    super.onMapCreated();
    // Map initialization is complete, ready to generate markers or widgets
  }
}