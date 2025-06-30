import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/mapview.dart';
import 'package:maps_poc/basicMap.dart';
import 'package:maps_poc/page.dart';
import 'package:maps_poc/pages/clusters/clusters.bloc.dart';
import 'package:maps_poc/pages/clusters/clusters.events.dart';
import 'package:maps_poc/pages/clusters/clusters.state.dart';

class Clusters extends StatefulWidget implements PocPage {
  const Clusters({super.key});

  @override
  final Widget leading = const Icon(Icons.bubble_chart_outlined);
  @override
  final String title = 'Clusters';
  @override
  final String subtitle = 'Display clustered earthquake data';

  @override
  State<StatefulWidget> createState() => _ClusterMap();
}

class _ClusterMap extends SimpleMapState {
  late final ClustersBloc _clustersBloc;

  @override
  void initState() {
    super.initState();
    _clustersBloc = ClustersBloc();
  }

  @override
  void dispose() {
    _clustersBloc.close();
    super.dispose();
  }

  void _loadClusters() {
    if (hereMapController != null) {
      _clustersBloc.add(LoadClusters(hereMapController: hereMapController!));
    }
  }

  void _clearClusters() {
    _clustersBloc.add(ClearClusters(hereMapController: hereMapController));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _clustersBloc,
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
                    Text(
                      'Earthquake Clusters',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<ClustersBloc, ClustersState>(
                      builder: (context, state) {
                        if (state is ClustersLoaded) {
                          return Column(
                            children: [
                              Text(
                                '${state.totalPoints} earthquake points clustered',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _clearClusters,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Clear Clusters'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        
                        final isLoading = state is ClustersLoading;
                        
                        return Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _loadClusters,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Load Clusters'),
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

          // Instructions Card
          Positioned(
            top: 140,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                      '• Zoom in/out to see clustering behavior',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '• Tap clusters to see details',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '• Numbers show earthquake count in cluster',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Cluster Info Card
          BlocBuilder<ClustersBloc, ClustersState>(
            builder: (context, state) {
              if (state is ClusterTapped) {
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
                              Icon(Icons.info, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Cluster Details',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Earthquakes in cluster: ${state.pointCount}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Center: ${state.center.latitude.toStringAsFixed(4)}, ${state.center.longitude.toStringAsFixed(4)}',
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
          BlocListener<ClustersBloc, ClustersState>(
            listener: (context, state) {
              if (state is ClustersLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${state.totalPoints} earthquake points loaded and clustered'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is ClustersError) {
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
          BlocBuilder<ClustersBloc, ClustersState>(
            builder: (context, state) {
              if (state is ClustersLoading) {
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
    
    // Set camera to show earthquake data area
    if (hereMapController != null) {
      const double distanceToEarthInMeters = 10000000; // Global view
      MapMeasure mapMeasureZoom = MapMeasure(MapMeasureKind.distanceInMeters, distanceToEarthInMeters);
      GeoCoordinates globalCenter = GeoCoordinates(10.867890040082585, -103.94925008414447);
      hereMapController!.camera.lookAtPointWithMeasure(globalCenter, mapMeasureZoom);

      // Set up tap listener for clusters
      hereMapController!.gestures.tapListener = ClusterTapListener(hereMapController!, _clustersBloc);
    }
  }
}

// Custom tap listener for cluster handling
class ClusterTapListener implements TapListener {
  final HereMapController mapController;
  final ClustersBloc clustersBloc;
  
  ClusterTapListener(this.mapController, this.clustersBloc);
  
  @override
  void onTap(Point2D origin) {
    // Convert screen coordinates to geo coordinates
    GeoCoordinates? geoCoordinates = mapController.viewToGeoCoordinates(origin);
    if (geoCoordinates != null) {
      // For now, simulate cluster tap with the tapped coordinates
      // In a real implementation, you'd need to check if the tap was on a cluster
      clustersBloc.add(TapCluster(
        center: geoCoordinates,
        markers: [], // Empty for now - would need cluster detection logic
      ));
    }
  }
}
