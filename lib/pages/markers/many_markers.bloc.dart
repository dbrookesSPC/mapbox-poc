import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'many_markers.events.dart';
import 'many_markers.state.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class ManyMarkersBloc extends Bloc<ManyMarkersEvent, ManyMarkersState> {
  MapImage? _markerImage;
  final List<MapMarker> _mapMarkers = [];
  final List<Widget> _herdWidgets = [];
  final List<GeoCoordinates> _markerPositions = [];
  final Random _random = Random();
  late AnimationController? _rotationController;

  ManyMarkersBloc() : super(ManyMarkersInitial()) {
    on<GenerateMarkers>(_onGenerateMarkers);
    on<GenerateHerdWidgets>(_onGenerateHerdWidgets);
    on<AddPolygon>(_onAddPolygon);
    on<AddMarker>(_onAddMarker);
    on<AddWidget>(_onAddWidget);
    on<AddLine>(_onAddLine);
    on<LoadJSONElementsComplete>(_onLoadJSONElementsComplete);
    on<ClearMarkers>(_onClearMarkers);
  }

  // Initialize rotation controller for herd widgets
  void initializeAnimationController(TickerProvider vsync) {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: vsync,
    );
    _rotationController!.repeat();
  }

  Future<void> _onGenerateMarkers(
    GenerateMarkers event,
    Emitter<ManyMarkersState> emit,
  ) async {
    try {
      emit(ManyMarkersLoading());
      
      // Initialize marker image if not already done
      if (_markerImage == null) {
        _markerImage = MapImage.withFilePathAndWidthAndHeight("assets/ano.png", 60, 60);
      }
      
      // Clear existing markers first
      await _clearMarkersFromMap(event.hereMapController);
      
      final rng = Random();
      const batchSize = 1000; // Process markers in batches for better performance
      
      // Generate marker positions first
      final positions = <GeoCoordinates>[];
      for (int i = 0; i < event.markerCount; i++) {
        final dx = (rng.nextDouble() - 0.5) * event.spread;
        final dy = (rng.nextDouble() - 0.5) * event.spread;
        final lng = event.centerLng + dx;
        final lat = event.centerLat + dy;
        
        positions.add(GeoCoordinates(lat, lng));
      }
      
      // Add markers in batches to avoid blocking UI
      for (int i = 0; i < positions.length; i += batchSize) {
        final endIndex = math.min(i + batchSize, positions.length);
        final batch = positions.sublist(i, endIndex);
        
        // Emit progress
        emit(ManyMarkersGenerating(
          generatedCount: i,
          totalCount: event.markerCount,
          type: "markers",
        ));
        
        // Add batch of markers
        await _addMarkerBatch(event.hereMapController, batch);
        
        // Allow UI to update
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      _markerPositions.addAll(positions);

      emit(ManyMarkersLoaded(
        markerPositions: List.from(_markerPositions),
        markerCount: _mapMarkers.length,
        type: "markers",
      ));
    } catch (e) {
      emit(ManyMarkersError(error: 'Failed to generate markers: $e'));
    }
  }

  Future<void> _onAddPolygon(
    AddPolygon event,
    Emitter<ManyMarkersState> emit,
  ) async {
    try {
      final polygon = GeoPolygon(event.points);
      final mapPolygon = MapPolygon(polygon, Color.fromARGB(150, 255, 0, 0));
      event.hereMapController.mapScene.addMapPolygon(mapPolygon);
    } catch (e) {
      emit(ManyMarkersError(error: 'Failed to add polygon: $e'));
    }
  }

  Future<void> _onAddMarker(
    AddMarker event,
    Emitter<ManyMarkersState> emit,
  ) async {
    try {
      // Create SVG marker based on type
      final markerImage = await _createSvgMarker(event.markerType ?? 'marker');
      final mapMarker = MapMarker(event.position, markerImage);
      event.hereMapController.mapScene.addMapMarker(mapMarker);
    } catch (e) {
      emit(ManyMarkersError(error: 'Failed to add marker: $e'));
    }
  }

  Future<void> _onAddWidget(
    AddWidget event,
    Emitter<ManyMarkersState> emit,
  ) async {
    try {
      final widget = _createHerdWidget(_random.nextInt(99) + 1);
      event.hereMapController.pinWidget(widget, event.position);
    } catch (e) {
      emit(ManyMarkersError(error: 'Failed to add widget: $e'));
    }
  }

  Future<void> _onAddLine(
    AddLine event,
    Emitter<ManyMarkersState> emit,
  ) async {
    try {
      final polyline = GeoPolyline([event.start, event.end]);
      final lineColor = Color.fromARGB(255, 0, 0, 255);
      final lineWidth = MapMeasureDependentRenderSize.withSingleSize(RenderSizeUnit.pixels, 5.0);
      final lineStyle = MapPolylineSolidRepresentation(
        lineWidth,
        lineColor,
        LineCap.round,
      );
      final mapPolyline = MapPolyline.withRepresentation(polyline, lineStyle);
      event.hereMapController.mapScene.addMapPolyline(mapPolyline);
    } catch (e) {
      emit(ManyMarkersError(error: 'Failed to add line: $e'));
    }
  }

  Future<void> _onLoadJSONElementsComplete(
    LoadJSONElementsComplete event,
    Emitter<ManyMarkersState> emit,
  ) async {
    emit(ManyMarkersElementsLoaded(
      polygonCount: event.polygonCount,
      markerCount: event.markerCount,
      widgetCount: event.widgetCount,
      lineCount: event.lineCount,
    ));
  }

  Future<void> _onGenerateHerdWidgets(
    GenerateHerdWidgets event,
    Emitter<ManyMarkersState> emit,
  ) async {
    try {
      emit(ManyMarkersLoading());
      
      // Clear existing items first
      await _clearMarkersFromMap(event.hereMapController);
      
      final rng = Random();
      const batchSize = 100; // Smaller batches for widgets as they're more complex
      
      // Generate widget positions first
      final positions = <GeoCoordinates>[];
      for (int i = 0; i < event.widgetCount; i++) {
        final dx = (rng.nextDouble() - 0.5) * event.spread;
        final dy = (rng.nextDouble() - 0.5) * event.spread;
        final lng = event.centerLng + dx;
        final lat = event.centerLat + dy;
        
        positions.add(GeoCoordinates(lat, lng));
      }
      
      // Add widgets in batches to avoid blocking UI
      for (int i = 0; i < positions.length; i += batchSize) {
        final endIndex = math.min(i + batchSize, positions.length);
        final batch = positions.sublist(i, endIndex);
        
        // Emit progress
        emit(ManyMarkersGenerating(
          generatedCount: i,
          totalCount: event.widgetCount,
          type: "widgets",
        ));
        
        // Add batch of widgets
        await _addHerdWidgetBatch(event.hereMapController, batch);
        
        // Allow UI to update
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      _markerPositions.addAll(positions);

      emit(ManyMarkersLoaded(
        markerPositions: List.from(_markerPositions),
        markerCount: _herdWidgets.length,
        type: "widgets",
      ));
    } catch (e) {
      emit(ManyMarkersError(error: 'Failed to generate herd widgets: $e'));
    }
  }

  Future<void> _addMarkerBatch(
    HereMapController mapController,
    List<GeoCoordinates> positions,
  ) async {
    for (final position in positions) {
      final mapMarker = MapMarker(position, _markerImage!);
      
      // Add to map scene
      mapController.mapScene.addMapMarker(mapMarker);
      
      // Track marker for cleanup
      _mapMarkers.add(mapMarker);
    }
  }

  Future<void> _addHerdWidgetBatch(
    HereMapController mapController,
    List<GeoCoordinates> positions,
  ) async {
    for (final position in positions) {
      // Generate random number between 1 and 99
      int randomNumber = _random.nextInt(99) + 1;
      
      Widget herdWidget = _createHerdWidget(randomNumber);
      
      // Pin widget to map
      mapController.pinWidget(herdWidget, position);
      
      // Track widget for cleanup
      _herdWidgets.add(herdWidget);
    }
  }

  Widget _createHerdWidget(int number) {
    return Container(
      width: 110,
      height: 46,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Speech bubble background
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/speech_bubble.svg',
              width: 110,
              height: 46,
              fit: BoxFit.contain,
              allowDrawingOutsideViewBox: true,
              matchTextDirection: false,
            ),
          ),
          // Cow icon
          Positioned(
            left: 16,
            top: 4,
            child: SvgPicture.asset(
              'assets/cow_icon.svg',
              width: 30,
              height: 24,
              fit: BoxFit.contain,
              allowDrawingOutsideViewBox: true,
              matchTextDirection: false,
            ),
          ),
          // Dynamic number
          Positioned(
            left: 47,
            top: 6,
            child: Text(
              number.toString(),
              style: const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          // Animated spinner (if animation controller is available)
          if (_rotationController != null)
            Positioned(
              left: 76,
              top: 7,
              child: AnimatedBuilder(
                animation: _rotationController!,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController!.value * 2 * pi,
                    child: SvgPicture.asset(
                      'assets/spinner_icon.svg',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      allowDrawingOutsideViewBox: true,
                      matchTextDirection: false,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onClearMarkers(
    ClearMarkers event,
    Emitter<ManyMarkersState> emit,
  ) async {
    try {
      if (event.hereMapController != null) {
        await _clearMarkersFromMap(event.hereMapController!);
      }
      emit(ManyMarkersInitial());
    } catch (e) {
      emit(ManyMarkersError(error: 'Failed to clear markers: $e'));
    }
  }

  Future<void> _clearMarkersFromMap(HereMapController mapController) async {
    // Remove all markers from map scene
    for (final marker in _mapMarkers) {
      mapController.mapScene.removeMapMarker(marker);
    }
    
    // Note: HERE SDK doesn't provide a direct way to remove pinned widgets
    // In a real implementation, you'd need to keep track of the pinned widgets
    // and manage them appropriately. For now, we'll clear our tracking list.
    _herdWidgets.clear();
    
    // Clear tracking lists
    _mapMarkers.clear();
    _markerPositions.clear();
  }

  // Helper method to create markers with different colors based on type
  Future<MapImage> _createSvgMarker(String markerType) async {
    // Use the converted PNG files from icons_png directory
    final Map<String, String> markerAssets = {
      'restaurant': 'assets/icons_png/restaurant.png',
      'hospital': 'assets/icons_png/hospital.png', 
      'school': 'assets/icons_png/school.png',
      'park': 'assets/icons_png/park.png',
      'bank': 'assets/icons_png/bank.png',
      'marker': 'assets/ano.png', // fallback to default marker
    };

    final asset = markerAssets[markerType] ?? markerAssets['marker']!;
    
    try {
      // Return different sized markers to distinguish types
      final size = _getMarkerSize(markerType);
      return MapImage.withFilePathAndWidthAndHeight(asset, size, size);
    } catch (e) {
      // Fallback to default marker
      return MapImage.withFilePathAndWidthAndHeight("assets/ano.png", 48, 48);
    }
  }

  // Helper method to get marker size based on type
  int _getMarkerSize(String markerType) {
    switch (markerType) {
      case 'restaurant':
        return 60;
      case 'hospital':
        return 65;
      case 'school':
        return 55;
      case 'park':
        return 70;
      case 'bank':
        return 50;
      default:
        return 60;
    }
  }

  // Helper method to get marker color based on type
  Color _getMarkerColor(String markerType) {
    switch (markerType) {
      case 'restaurant':
        return Colors.orange;
      case 'hospital':
        return Colors.red;
      case 'school':
        return Colors.blue;
      case 'park':
        return Colors.green;
      case 'bank':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Future<void> close() {
    _rotationController?.dispose();
    return super.close();
  }
}
