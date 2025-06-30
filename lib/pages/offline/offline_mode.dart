import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
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
  final String subtitle = 'Download maps for offline use';

  @override
  State<StatefulWidget> createState() => _OfflineMap();
}

class _OfflineMap extends SimpleMapState {
  late final OfflineBloc _offlineBloc;

  @override
  void initState() {
    super.initState();
    _offlineBloc = OfflineBloc();
  }

  @override
  void dispose() {
    _offlineBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _offlineBloc,
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
                      'Offline Maps',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<OfflineBloc, OfflineState>(
                      builder: (context, state) {
                        final isLoading = state is OfflineLoading || state is OfflineDownloadProgress;
                        
                        return Column(
                          children: [
                            // First row of buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : () {
                                      _offlineBloc.add(LoadAvailableRegions());
                                    },
                                    child: const Text('Load Regions'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : () {
                                      _offlineBloc.add(DownloadRegion(regionName: 'Switzerland'));
                                    },
                                    child: const Text('Download CH'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Second row of buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isLoading || hereMapController == null ? null : () {
                                      _offlineBloc.add(DownloadCurrentViewArea(
                                        hereMapController: hereMapController!,
                                      ));
                                    },
                                    child: const Text('Download View'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : () {
                                      _offlineBloc.add(DeleteAllRegions());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Delete All'),
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

          // Offline/Online Toggle
          Positioned(
            top: 160,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Text('Mode:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _offlineBloc.add(const ToggleOfflineMode(isOffline: false));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Online'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _offlineBloc.add(const ToggleOfflineMode(isOffline: true));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Offline'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _offlineBloc.add(ClearCache());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Clear Cache'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                            value: state.percentage / 100.0,
                          ),
                          const SizedBox(height: 4),
                          Text('${state.percentage}%'),
                          if (state.regionId != null)
                            Text('Region ID: ${state.regionId!.id}'),
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
              } else if (state is OfflineRegionsLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Loaded ${state.regions.length} regions'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            child: const SizedBox.shrink(),
          ),

          // Loading Indicator
          BlocBuilder<OfflineBloc, OfflineState>(
            builder: (context, state) {
              if (state is OfflineLoading) {
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
    
    // Initialize offline manager once the HERE map controller is ready
    if (hereMapController != null) {
      _offlineBloc.add(InitializeOfflineManager(
        hereMapController: hereMapController!,
      ));
    }
  }
}