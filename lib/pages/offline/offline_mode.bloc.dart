import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/maploader.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';
import 'offline_mode.events.dart';
import 'offline_mode.state.dart';

class OfflineBloc extends Bloc<OfflineEvent, OfflineState> {
  MapDownloader? _mapDownloader;
  OfflineSearchEngine? _offlineSearchEngine;
  List<Region> _downloadableRegions = [];
  List<MapDownloaderTask> _mapDownloaderTasks = [];

  OfflineBloc() : super(OfflineInitial()) {
    on<InitializeOfflineManager>(_onInitializeOfflineManager);
    on<LoadAvailableRegions>(_onLoadAvailableRegions);
    on<DownloadRegion>(_onDownloadRegion);
    on<DownloadCurrentViewArea>(_onDownloadCurrentViewArea);
    on<SearchOffline>(_onSearchOffline);
    on<DeleteAllRegions>(_onDeleteAllRegions);
    on<ToggleOfflineMode>(_onToggleOfflineMode);
    on<ClearCache>(_onClearCache);
  }

  Future<void> _onInitializeOfflineManager(
    InitializeOfflineManager event,
    Emitter<OfflineState> emit,
  ) async {
    try {
      emit(OfflineLoading());

      // Initialize offline search engine
      try {
        _offlineSearchEngine = OfflineSearchEngine();
      } on InstantiationException {
        print("Initialization of OfflineSearchEngine failed.");
      }

      // Get SDK engine
      SDKNativeEngine? sdkNativeEngine = SDKNativeEngine.sharedInstance;
      if (sdkNativeEngine == null) {
        emit(const OfflineError(error: "SDKNativeEngine not initialized."));
        return;
      }

      // Initialize MapDownloader
      MapDownloader.fromSdkEngineAsync(sdkNativeEngine, (mapDownloader) {
        _mapDownloader = mapDownloader;
        _checkInstallationStatus();
      });

      emit(OfflineInitial());
    } catch (e) {
      emit(OfflineError(error: 'Failed to initialize offline manager: $e'));
    }
  }

  Future<void> _onLoadAvailableRegions(
    LoadAvailableRegions event,
    Emitter<OfflineState> emit,
  ) async {
    try {
      if (_mapDownloader == null) {
        emit(const OfflineError(error: "MapDownloader not ready"));
        return;
      }

      emit(OfflineLoading());

      // Create a completer to convert the callback-based API to async/await
      final completer = Completer<List<Region>>();

      _mapDownloader!.getDownloadableRegionsWithLanguageCode(
        LanguageCode.enUs,
        (MapLoaderError? mapLoaderError, List<Region>? list) {
          if (mapLoaderError != null) {
            completer.completeError(mapLoaderError);
            return;
          }
          completer.complete(list!);
        },
      );

      // Wait for the operation to complete
      final regions = await completer.future;
      
      // Now emit safely after the async operation is done
      if (!emit.isDone) {
        _downloadableRegions = regions;
        emit(OfflineRegionsLoaded(regions: _downloadableRegions));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(OfflineError(error: 'Failed to load regions: $e'));
      }
    }
  }

  Future<void> _onDownloadRegion(
    DownloadRegion event,
    Emitter<OfflineState> emit,
  ) async {
    try {
      if (_mapDownloader == null) {
        emit(const OfflineError(error: "MapDownloader not ready"));
        return;
      }

      Region? region = _findRegion(event.regionName);
      if (region == null) {
        emit(OfflineError(error: "Region '${event.regionName}' not found. Load regions first."));
        return;
      }

      List<RegionId> regionIDs = [region.regionId];

      // Create a completer for the download completion
      final completer = Completer<List<RegionId>?>();

      MapDownloaderTask mapDownloaderTask = _mapDownloader!.downloadRegions(
        regionIDs,
        DownloadRegionsStatusListener(
          (MapLoaderError? mapLoaderError, List<RegionId>? list) {
            // Handle completion
            if (mapLoaderError != null) {
              completer.completeError(mapLoaderError);
              return;
            }
            completer.complete(list);
          },
          (RegionId regionId, int percentage) {
            // Handle progress - emit immediately since this is synchronous
            if (!emit.isDone) {
              emit(OfflineDownloadProgress(
                percentage: percentage,
                currentTask: "Downloading ${event.regionName}",
                regionId: regionId,
              ));
            }
          },
          (MapLoaderError? mapLoaderError) {
            // Handle pause
            if (mapLoaderError == null) {
              if (!completer.isCompleted) {
                completer.completeError("Download was paused");
              }
            } else {
              if (!completer.isCompleted) {
                completer.completeError(mapLoaderError);
              }
            }
          },
          () {
            // Handle resume
            print("Download resumed");
          },
        ),
      );

      _mapDownloaderTasks.add(mapDownloaderTask);

      // Wait for download completion
      await completer.future;

      // Emit completion safely
      if (!emit.isDone) {
        List<InstalledRegion> installedRegions = _getInstalledRegions();
        emit(OfflineDownloadComplete(
          message: "Download completed for ${event.regionName}!",
          installedRegions: installedRegions,
        ));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(OfflineError(error: 'Failed to download region: $e'));
      }
    }
  }

  Future<void> _onDownloadCurrentViewArea(
    DownloadCurrentViewArea event,
    Emitter<OfflineState> emit,
  ) async {
    try {
      if (_mapDownloader == null) {
        emit(const OfflineError(error: "MapDownloader not ready"));
        return;
      }

      GeoBox geoBox = _getMapViewGeoBox(event.hereMapController);
      GeoPolygon polygonArea = GeoPolygon.withGeoBox(geoBox);

      // Create a completer for the download completion
      final completer = Completer<List<RegionId>?>();

      MapDownloaderTask mapDownloaderTask = _mapDownloader!.downloadArea(
        polygonArea,
        DownloadRegionsStatusListener(
          (MapLoaderError? mapLoaderError, List<RegionId>? list) {
            // Handle completion
            if (mapLoaderError != null) {
              completer.completeError(mapLoaderError);
              return;
            }
            completer.complete(list);
          },
          (RegionId regionId, int percentage) {
            // Handle progress - emit immediately since this is synchronous
            if (!emit.isDone) {
              emit(OfflineDownloadProgress(
                percentage: percentage,
                currentTask: "Downloading current view area",
                regionId: regionId,
              ));
            }
          },
          (MapLoaderError? mapLoaderError) {
            // Handle pause/error
            if (mapLoaderError == null) {
              if (!completer.isCompleted) {
                completer.completeError("Area download was paused");
              }
            } else {
              if (!completer.isCompleted) {
                completer.completeError(mapLoaderError);
              }
            }
          },
          () {
            // Handle resume
            print("Area download resumed");
          },
        ),
      );

      _mapDownloaderTasks.add(mapDownloaderTask);

      // Wait for download completion
      await completer.future;

      // Emit completion safely
      if (!emit.isDone) {
        List<InstalledRegion> installedRegions = _getInstalledRegions();
        emit(OfflineDownloadComplete(
          message: "Current view area downloaded for offline use!",
          installedRegions: installedRegions,
        ));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(OfflineError(error: 'Failed to download current view: $e'));
      }
    }
  }

  Future<void> _onSearchOffline(
    SearchOffline event,
    Emitter<OfflineState> emit,
  ) async {
    try {
      if (_offlineSearchEngine == null) {
        emit(const OfflineError(error: "OfflineSearchEngine not ready"));
        return;
      }

      GeoBox? viewportGeoBox = event.hereMapController.camera.boundingBox;
      if (viewportGeoBox == null) {
        emit(const OfflineError(error: "Cannot get viewport bounds for search"));
        return;
      }

      TextQueryArea queryArea = TextQueryArea.withBox(viewportGeoBox);
      TextQuery query = TextQuery.withArea(event.query, queryArea);

      SearchOptions searchOptions = SearchOptions();
      searchOptions.languageCode = LanguageCode.enUs;
      searchOptions.maxItems = 30;

      _offlineSearchEngine!.searchByText(
        query,
        searchOptions,
        (SearchError? searchError, List<Place>? list) async {
          if (searchError != null) {
            emit(OfflineError(error: "Search error: $searchError"));
            return;
          }

          List<String> results = list!
              .map((place) => "${place.title} - ${place.address.addressText}")
              .toList();

          emit(OfflineSearchResults(
            results: results,
            query: event.query,
          ));
        },
      );
    } catch (e) {
      emit(OfflineError(error: 'Failed to search offline: $e'));
    }
  }

  Future<void> _onDeleteAllRegions(
    DeleteAllRegions event,
    Emitter<OfflineState> emit,
  ) async {
    try {
      if (_mapDownloader == null) {
        emit(const OfflineError(error: "MapDownloader not ready"));
        return;
      }

      List<InstalledRegion> installedRegions = _getInstalledRegions();
      List<RegionId> regionIds = installedRegions.map((region) => region.regionId).toList();

      if (regionIds.isEmpty) {
        emit(const OfflineError(error: "No regions to delete"));
        return;
      }

      // Create a completer for the delete operation
      final completer = Completer<List<RegionId>?>();

      _mapDownloader!.deleteRegions(
        regionIds,
        (MapLoaderError? error, List<RegionId>? deletedRegions) {
          if (error == null && deletedRegions != null) {
            completer.complete(deletedRegions);
          } else {
            completer.completeError(error ?? "Unknown delete error");
          }
        },
      );

      // Wait for the operation to complete
      await completer.future;

      // Emit completion safely
      if (!emit.isDone) {
        emit(const OfflineDownloadComplete(
          message: "All regions deleted successfully",
          installedRegions: [],
        ));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(OfflineError(error: 'Failed to delete regions: $e'));
      }
    }
  }

  Future<void> _onToggleOfflineMode(
    ToggleOfflineMode event,
    Emitter<OfflineState> emit,
  ) async {
    try {
      SDKNativeEngine.sharedInstance?.isOfflineMode = event.isOffline;
      emit(OfflineDownloadComplete(
        message: event.isOffline ? "App is now offline" : "App is now online",
        installedRegions: _getInstalledRegions(),
      ));
    } catch (e) {
      emit(OfflineError(error: 'Failed to toggle offline mode: $e'));
    }
  }

  Future<void> _onClearCache(
    ClearCache event,
    Emitter<OfflineState> emit,
  ) async {
    try {
      // Create a completer to convert the callback-based API to async/await
      final completer = Completer<void>();
      
      SDKCache.fromSdkEngine(SDKNativeEngine.sharedInstance!).clearAppCache(
        (mapLoaderError) {
          if (mapLoaderError != null) {
            completer.completeError(mapLoaderError);
          } else {
            completer.complete();
          }
        },
      );
      
      // Wait for the operation to complete
      await completer.future;
      
      // Now emit safely after the async operation is done
      if (!emit.isDone) {
        emit(const OfflineDownloadComplete(
          message: "Cache cleared successfully",
          installedRegions: [],
        ));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(OfflineError(error: 'Failed to clear cache: $e'));
      }
    }
  }

  // Helper methods
  Region? _findRegion(String localizedRegionName) {
    for (Region region in _downloadableRegions) {
      if (region.name == localizedRegionName) {
        return region;
      }

      List<Region>? childRegions = region.childRegions;
      if (childRegions != null) {
        for (Region childRegion in childRegions) {
          if (childRegion.name == localizedRegionName) {
            return childRegion;
          }
        }
      }
    }
    return null;
  }

  GeoBox _getMapViewGeoBox(HereMapController hereMapController) {
    MapCamera camera = hereMapController.camera;
    GeoBox? geoBox = camera.boundingBox;
    if (geoBox == null) {
      // Fallback to a fixed box around current camera target
      GeoCoordinates southWestCorner = GeoCoordinates(
        camera.state.targetCoordinates.latitude - 0.05,
        camera.state.targetCoordinates.longitude - 0.05,
      );
      GeoCoordinates northEastCorner = GeoCoordinates(
        camera.state.targetCoordinates.latitude + 0.05,
        camera.state.targetCoordinates.longitude + 0.05,
      );
      geoBox = GeoBox(southWestCorner, northEastCorner);
    }
    return geoBox;
  }

  List<InstalledRegion> _getInstalledRegions() {
    if (_mapDownloader == null) return [];
    try {
      return _mapDownloader!.getInstalledRegions();
    } on MapLoaderExceptionException catch (e) {
      print("Error while fetching installed regions: ${e.error.toString()}");
      return [];
    }
  }

  void _checkInstallationStatus() {
    if (_mapDownloader == null) return;

    PersistentMapStatus persistentMapStatus = _mapDownloader!.getInitialPersistentMapStatus();
    if (persistentMapStatus != PersistentMapStatus.ok) {
      print("PersistentMapStatus: The persistent map data seems to be corrupted. Trying to repair.");
      _mapDownloader!.repairPersistentMap((PersistentMapRepairError? persistentMapRepairError) {
        if (persistentMapRepairError == null) {
          print("RepairPersistentMap: Repair operation completed successfully!");
        } else {
          print("RepairPersistentMap: Repair operation failed: $persistentMapRepairError");
        }
      });
    }
  }

  @override
  Future<void> close() {
    // Cancel any ongoing downloads
    for (MapDownloaderTask task in _mapDownloaderTasks) {
      task.cancel();
    }
    _mapDownloaderTasks.clear();
    return super.close();
  }
}