import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
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
  final String title = 'Performance Test';
  @override
  final String subtitle = 'Test 15K markers or 1K custom widgets';

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

  void _generateMarkers() {
    if (hereMapController == null) return;
    
    // Use current map center or default center
    final centerLat = defaultCenter.latitude;
    final centerLng = defaultCenter.longitude;
    
    _markersBloc.add(GenerateMarkers(
      centerLng: centerLng,
      centerLat: centerLat,
      hereMapController: hereMapController!,
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
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
                        
                        return Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isLoading ? null : _generateMarkers,
                                icon: isLoading && state is ManyMarkersGenerating && state.type == "markers"
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.location_on),
                                label: const Text('15K Markers'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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
    // Map initialization is complete, ready to generate markers or widgets
  }
}