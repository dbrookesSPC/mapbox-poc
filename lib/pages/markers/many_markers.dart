import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps_poc/basicMap.dart';
import 'package:maps_poc/page.dart';
import 'package:maps_poc/pages/markers/many_markers.bloc.dart';
import 'package:maps_poc/pages/markers/many_markers.events.dart';
import 'package:maps_poc/pages/markers/many_markers.state.dart';

class ManyMarkers extends StatefulWidget implements PocPage {
  const ManyMarkers({super.key});

  @override
  final Widget leading = const Icon(Icons.location_on_outlined);
  @override
  final String title = '15K Markers';
  @override
  final String subtitle = 'Display 15,000 markers on the map';

  @override
  State<StatefulWidget> createState() => _ManyMarkersMap();
}

class _ManyMarkersMap extends SimpleMapState {
  late final ManyMarkersBloc _markersBloc;

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

  void _generateMarkers() {
    if (mapboxMap == null) return;
    
    final centerLng = camera.center!.coordinates.lng;
    final centerLat = camera.center!.coordinates.lat;
    
    _markersBloc.add(GenerateMarkers(
      centerLng: centerLng.toDouble(),
      centerLat: centerLat.toDouble(),
      mapboxMap: mapboxMap!,
    ));
  }

  void _clearMarkers() {
    _markersBloc.add(ClearMarkers(mapboxMap: mapboxMap));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _markersBloc,
      child: Stack(
        children: [
          super.build(context), // MapWidget
          
          // Control Panel
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Generate 15K Markers',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          BlocBuilder<ManyMarkersBloc, ManyMarkersState>(
                            builder: (context, state) {
                              if (state is ManyMarkersLoaded) {
                                return Text(
                                  '${state.markerCount} markers displayed',
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              }
                              return Text(
                                'Tap generate to add markers',
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
                        
                        return Row(
                          children: [
                            ElevatedButton(
                              onPressed: isLoading ? null : _generateMarkers,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Generate'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: isLoading ? null : _clearMarkers,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Clear'),
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
                            'Generating markers...',
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

          // Status Messages
          BlocListener<ManyMarkersBloc, ManyMarkersState>(
            listener: (context, state) {
              if (state is ManyMarkersLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${state.markerCount} markers generated successfully'),
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

  @override
  onMapCreated() async {
    super.onMapCreated();
    // Map initialization is now handled in the BLoC when generating markers
  }
}