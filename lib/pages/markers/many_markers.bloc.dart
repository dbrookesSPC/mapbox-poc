import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'many_markers.events.dart';
import 'many_markers.state.dart';

class ManyMarkersBloc extends Bloc<ManyMarkersEvent, ManyMarkersState> {
  static const String _markerImageId = "marker-icon";
  static const String _sourceId = "markers-source";
  static const String _layerId = "markers-layer";

  ManyMarkersBloc() : super(ManyMarkersInitial()) {
    on<GenerateMarkers>(_onGenerateMarkers);
    on<ClearMarkers>(_onClearMarkers);
  }

  Future<void> _onGenerateMarkers(
    GenerateMarkers event,
    Emitter<ManyMarkersState> emit,
  ) async {
    try {
      emit(ManyMarkersLoading());
      
      // Add marker image to style if not already present
      await _addMarkerImageToStyle(event.mapboxMap);
      
      final features = <Map<String, dynamic>>[];
      final rng = Random();
      const batchSize = 1000; // Process markers in batches
      
      for (int i = 0; i < event.markerCount; i++) {
        // Emit progress every batch
        if (i % batchSize == 0) {
          emit(ManyMarkersGenerating(
            generatedCount: i,
            totalCount: event.markerCount,
          ));
          // Allow UI to update
          await Future.delayed(const Duration(milliseconds: 1));
        }

        final dx = (rng.nextDouble() - 0.5) * event.spread;
        final dy = (rng.nextDouble() - 0.5) * event.spread;
        final lng = event.centerLng + dx;
        final lat = event.centerLat + dy;

        features.add({
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [lng, lat]
          },
          "properties": {
            "id": i,
            "title": "Marker $i",
          }
        });
      }

      final geoJsonData = {
        "type": "FeatureCollection",
        "features": features
      };

      // Add markers to map
      await _addMarkersToMap(event.mapboxMap, geoJsonData);

      emit(ManyMarkersLoaded(
        geoJsonData: geoJsonData,
        markerCount: event.markerCount,
      ));
    } catch (e) {
      emit(ManyMarkersError(error: 'Failed to generate markers: $e'));
    }
  }

  Future<void> _onClearMarkers(
    ClearMarkers event,
    Emitter<ManyMarkersState> emit,
  ) async {
    try {
      if (event.mapboxMap != null) {
        await _removeMarkersFromMap(event.mapboxMap!);
      }
      emit(ManyMarkersInitial());
    } catch (e) {
      emit(ManyMarkersError(error: 'Failed to clear markers: $e'));
    }
  }

  Future<void> _addMarkerImageToStyle(MapboxMap mapboxMap) async {
    try {
      final ByteData bytes = await rootBundle.load('assets/ano.png');
      final imageData = bytes.buffer.asUint8List();
      
      await mapboxMap.style.addStyleImage(
        _markerImageId,
        1.0,
        MbxImage(
          width: 64,
          height: 64,
          data: imageData,
        ),
        false,
        [],
        [],
        null,
      );
    } catch (e) {
      // Image might already exist, ignore error
    }
  }

  Future<void> _addMarkersToMap(
    MapboxMap mapboxMap,
    Map<String, dynamic> geoJsonData,
  ) async {
    // Remove existing source and layer if they exist
    await _removeMarkersFromMap(mapboxMap);

    // Add GeoJSON source
    await mapboxMap.style.addSource(GeoJsonSource(
      id: _sourceId,
      data: jsonEncode(geoJsonData),
    ));

    // Add symbol layer
    await mapboxMap.style.addLayer(SymbolLayer(
      id: _layerId,
      sourceId: _sourceId,
      iconImage: _markerImageId,
      iconSize: 0.06,
      iconAllowOverlap: true,
    ));
  }

  Future<void> _removeMarkersFromMap(MapboxMap mapboxMap) async {
    try {
      final layerExists = await mapboxMap.style.styleLayerExists(_layerId);
      if (layerExists) {
        await mapboxMap.style.removeStyleLayer(_layerId);
      }

      final sourceExists = await mapboxMap.style.styleSourceExists(_sourceId);
      if (sourceExists) {
        await mapboxMap.style.removeStyleSource(_sourceId);
      }
    } catch (e) {
      // Ignore errors if source/layer doesn't exist
    }
  }
}