import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:maps_poc/basicMap.dart';
import 'package:maps_poc/page.dart';
import 'package:maps_poc/pages/annotations/annotations.bloc.dart';
import 'package:maps_poc/pages/annotations/annotations.events.dart';
import 'package:maps_poc/pages/annotations/annotations.state.dart';

class Annotations extends StatefulWidget implements PocPage {
  const Annotations({super.key});

  @override
  final Widget leading = const Icon(Icons.map_outlined);
  @override
  final String title = 'Annotations (Markers)';
  @override
  final String subtitle = 'Tap on the map to add annotations';

  @override
  State<StatefulWidget> createState() => _AnnotationMap();
}

class _AnnotationMap extends SimpleMapState {
  late final AnnotationsBloc _annotationsBloc;

  @override
  void initState() {
    super.initState();
    _annotationsBloc = AnnotationsBloc();
  }

  @override
  void dispose() {
    _annotationsBloc.close();
    super.dispose();
  }

  void _clearAnnotations() {
    _annotationsBloc.add(ClearAnnotations(
      pointAnnotationManager: pointAnnotationManager,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _annotationsBloc,
      child: Stack(
        children: [
          super.build(context), // MapWidget
          
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
                                'Tap anywhere on the map to add annotations',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _clearAnnotations,
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
          BlocBuilder<AnnotationsBloc, AnnotationsState>(
            builder: (context, state) {
              final annotationCount = state is AnnotationsReady 
                  ? state.tapPositions.length
                  : state is AnnotationAdded 
                      ? state.tapPositions.length
                      : 0;

              if (annotationCount > 0) {
                return Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Annotations: $annotationCount',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
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
          BlocListener<AnnotationsBloc, AnnotationsState>(
            listener: (context, state) {
              if (state is AnnotationAdded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Annotation added at ${state.newPosition.lat.toStringAsFixed(4)}, ${state.newPosition.lng.toStringAsFixed(4)}',
                    ),
                    duration: const Duration(seconds: 1),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is AnnotationsCleared) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All annotations cleared'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else if (state is AnnotationsError) {
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
          BlocBuilder<AnnotationsBloc, AnnotationsState>(
            builder: (context, state) {
              if (state is AnnotationsLoading) {
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
    
    // Initialize annotations once the point annotation manager is ready
    if (pointAnnotationManager != null) {
      _annotationsBloc.add(InitializeAnnotations(
        pointAnnotationManager: pointAnnotationManager!,
      ));
    }
  }

  @override
  Future<void> onTapListener(MapContentGestureContext context) async {
    // Handle tap events through the BLoC
    final lng = context.point.coordinates.lng;
    final lat = context.point.coordinates.lat;
    
    if (pointAnnotationManager != null) {
      _annotationsBloc.add(AddAnnotation(
        lng: lng.toDouble(),
        lat: lat.toDouble(),
        pointAnnotationManager: pointAnnotationManager!,
      ));
    }
  }
}