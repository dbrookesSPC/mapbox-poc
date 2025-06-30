import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'offline_mode.events.dart';
import 'offline_mode.state.dart';

class OfflineBloc extends Bloc<OfflineEvent, OfflineState> {
  OfflineManager? _offlineManager;
  TileStore? _tileStore;
  final String _tileRegionId = 'offline-region';

  OfflineBloc() : super(OfflineInitial()) {
    on<InitializeOfflineManager>(_onInitializeOfflineManager);
    on<SaveCurrentViewOffline>(_onSaveCurrentViewOffline);
  }

  Future<void> _onInitializeOfflineManager(
    InitializeOfflineManager event,
    Emitter<OfflineState> emit,
  ) async {
    try {
      emit(OfflineLoading());
      _offlineManager = await OfflineManager.create();
      _tileStore = await TileStore.createDefault();
      _tileStore?.setDiskQuota(null);
      emit(OfflineInitial());
    } catch (e) {
      emit(OfflineError(error: 'Failed to initialize offline manager: $e'));
    }
  }

  Future<void> _onSaveCurrentViewOffline(
    SaveCurrentViewOffline event,
    Emitter<OfflineState> emit,
  ) async {
    try {
      emit(const OfflineDownloadProgress(
        styleProgress: 0,
        tileProgress: 0,
        currentTask: 'Starting download...',
      ));

      // Download style pack
      await _downloadStylePack(emit);
      
      // Download tile region
      await _downloadTileRegion(event.cameraState, emit);

      emit(const OfflineDownloadComplete(
        message: 'Current view saved for offline use',
      ));
    } catch (e) {
      emit(OfflineError(error: 'Failed to save offline data: $e'));
    }
  }

  Future<void> _downloadStylePack(Emitter<OfflineState> emit) async {
    final opts = StylePackLoadOptions(
      glyphsRasterizationMode: GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY,
      metadata: {'name': 'offline'},
      acceptExpired: false,
    );

    await _offlineManager?.loadStylePack(
      MapboxStyles.STANDARD_SATELLITE,
      opts,
      (progress) {
        final pct = progress.completedResourceCount / progress.requiredResourceCount;
        if (state is OfflineDownloadProgress) {
          final currentState = state as OfflineDownloadProgress;
          emit(OfflineDownloadProgress(
            styleProgress: pct,
            tileProgress: currentState.tileProgress,
            currentTask: 'Downloading style pack...',
          ));
        }
      },
    );
  }

  Future<void> _downloadTileRegion(CameraState cameraState, Emitter<OfflineState> emit) async {
    final pt = cameraState.center as Point;
    final lon = pt.coordinates.lng;
    final lat = pt.coordinates.lat;
    const delta = 0.05;

    final geometry = {
      'type': 'Polygon',
      'coordinates': [
        [
          [lon - delta, lat - delta],
          [lon - delta, lat + delta],
          [lon + delta, lat + delta],
          [lon + delta, lat - delta],
          [lon - delta, lat - delta],
        ],
      ],
    };

    final opts = TileRegionLoadOptions(
      geometry: geometry,
      descriptorsOptions: [
        TilesetDescriptorOptions(
          styleURI: MapboxStyles.STANDARD_SATELLITE,
          minZoom: (cameraState.zoom - 1).floor(),
          maxZoom: (cameraState.zoom + 1).ceil(),
        ),
      ],
      acceptExpired: true,
      networkRestriction: NetworkRestriction.NONE,
    );

    await _tileStore?.loadTileRegion(_tileRegionId, opts, (progress) {
      final pct = progress.completedResourceCount / progress.requiredResourceCount;
      if (state is OfflineDownloadProgress) {
        final currentState = state as OfflineDownloadProgress;
        emit(OfflineDownloadProgress(
          styleProgress: currentState.styleProgress,
          tileProgress: pct,
          currentTask: 'Downloading tiles...',
        ));
      }
    });
  }

  @override
  Future<void> close() {
    return super.close();
  }
}