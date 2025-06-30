import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:maps_poc/basicMap.dart';
import 'package:maps_poc/page.dart';
import 'package:maps_poc/pages/offline/offline_mode.bloc.dart';
import 'package:maps_poc/pages/offline/offline_mode.events.dart';
import 'package:maps_poc/pages/offline/offline_mode.state.dart';

class OfflineMode extends StatefulWidget implements PocPage {
  const OfflineMode({super.key});

  @override
  final Widget leading = const Icon(Icons.download_for_offline_outlined);
  @override
  final String title = 'Offline Mode';
  @override
  final String subtitle = 'Load map tiles offline';

  @override
  State<StatefulWidget> createState() => _OfflineMap();
}

class _OfflineMap extends SimpleMapState {
  late final OfflineBloc _offlineBloc;

  @override
  void initState() {
    super.initState();
    _offlineBloc = OfflineBloc();
    _offlineBloc.add(InitializeOfflineManager());
  }

  @override
  void dispose() {
    _offlineBloc.close();
    super.dispose();
  }

  Future<void> _saveCurrentViewOffline() async {
    if (mapboxMap == null) return;
    
    final cameraState = await mapboxMap!.getCameraState();
    _offlineBloc.add(SaveCurrentViewOffline(cameraState: cameraState));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _offlineBloc,
      child: Stack(
        children: [
          super.build(context), // MapWidget
          
          // Floating Action Button
          Positioned(
            top: 16,
            right: 16,
            child: BlocBuilder<OfflineBloc, OfflineState>(
              builder: (context, state) {
                final isLoading = state is OfflineLoading || state is OfflineDownloadProgress;
                
                return FloatingActionButton(
                  onPressed: isLoading ? null : _saveCurrentViewOffline,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_alt),
                  tooltip: 'Save current view offline',
                );
              },
            ),
          ),

          // Progress Indicator
          BlocBuilder<OfflineBloc, OfflineState>(
            builder: (context, state) {
              if (state is OfflineDownloadProgress) {
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
                            state.currentTask,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: state.styleProgress,
                            backgroundColor: Colors.grey[300],
                          ),
                          const SizedBox(height: 4),
                          Text('Style: ${(state.styleProgress * 100).toInt()}%'),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: state.tileProgress,
                            backgroundColor: Colors.grey[300],
                          ),
                          const SizedBox(height: 4),
                          Text('Tiles: ${(state.tileProgress * 100).toInt()}%'),
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
          BlocListener<OfflineBloc, OfflineState>(
            listener: (context, state) {
              if (state is OfflineDownloadComplete) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is OfflineError) {
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
  }
}