import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'polygons.events.dart';
import 'polygons.state.dart';

class PolygonsBloc extends Bloc<PolygonsEvent, PolygonsState> {
  static const String _sourceId = "polygon";
  static const String _fillLayerId = "fill-layer2";
  static const String _lineLayerId = "outline-layer2";

  Uint8List? _annotationImage;
  final List<Position> _tapPositions = [];
  final List<Map<String, dynamic>> _polygonFeatures = [];
  final Random _rnd = Random();
  GeoJsonSource? _geoJsonSource;

  final List<String> _adjectives = [
    'Ancient', 'Misty', 'Silent', 'Red', 'Golden', 'Hidden', 'Lonely', 'Flying'
  ];
  final List<String> _nouns = [
    'Forest', 'Mountain', 'River', 'Valley', 'Peak', 'Island', 'Canyon', 'Lake'
  ];

  PolygonsBloc() : super(PolygonsInitial()) {
    on<InitializePolygons>(_onInitializePolygons);
    on<AddPoint>(_onAddPoint);
    on<CreatePolygon>(_onCreatePolygon);
    on<TapPolygon>(_onTapPolygon);
    on<ClearAll>(_onClearAll);
  }

  Future<void> _onInitializePolygons(
    InitializePolygons event,
    Emitter<PolygonsState> emit,
  ) async {
    try {
      emit(PolygonsLoading());

      // Load the annotation image
      final ByteData bytes = await rootBundle.load('assets/ano.png');
      _annotationImage = bytes.buffer.asUint8List();

      // Initialize empty GeoJSON source
      final emptyCollection = {"type": "FeatureCollection", "features": []};
      _geoJsonSource = GeoJsonSource(
        id: _sourceId,
        data: json.encode(emptyCollection),
      );

      // Add source and layers to map
      await event.mapboxMap.style.addSource(_geoJsonSource!);

      await event.mapboxMap.style.addLayer(
        FillLayer(
          id: _fillLayerId,
          sourceId: _sourceId,
          fillColor: const Color.fromARGB(151, 250, 0, 0).value,
        ),
      );

      await event.mapboxMap.style.addLayer(
        LineLayer(
          id: _lineLayerId,
          sourceId: _sourceId,
          lineColor: const Color(0xFF0000FF).value,
          lineWidth: 2.0,
        ),
      );

      // Add tap interaction for polygons
      final tapInteraction = TapInteraction(
        FeaturesetDescriptor(layerId: _fillLayerId),
        (feature, context) async {
 var featureId = feature.id.toString();
        // Handle tap when a feature from "polygons" is tapped.
        print("Tapped feature: $featureId");
        print("Tapped feature properties: ${feature.properties}");
        print("Tapped feature name: ${feature.properties['name']}");
        print("Tapped feature coordinates: ${feature.geometry.toString()}");        },
      );
      event.mapboxMap.addInteraction(tapInteraction);

      emit(PolygonsReady(
        tapPositions: List.from(_tapPositions),
        polygonFeatures: List.from(_polygonFeatures),
      ));
    } catch (e) {
      emit(PolygonsError(error: 'Failed to initialize polygons: $e'));
    }
  }

  Future<void> _onAddPoint(
    AddPoint event,
    Emitter<PolygonsState> emit,
  ) async {
    try {
      if (_annotationImage == null) {
        emit(const PolygonsError(error: 'Annotation image not loaded'));
        return;
      }

      final position = Position(event.lng, event.lat);
      final opts = PointAnnotationOptions(
        geometry: Point(coordinates: position),
        image: _annotationImage,
        iconSize: 0.4,
      );

      // Create the annotation on the map
      await event.pointAnnotationManager.create(opts);

      // Add to our local list
      _tapPositions.add(position);

      emit(PointAdded(
        tapPositions: List.from(_tapPositions),
        newPosition: position,
        polygonFeatures: List.from(_polygonFeatures),
      ));
    } catch (e) {
      emit(PolygonsError(error: 'Failed to add point: $e'));
    }
  }

  Future<void> _onCreatePolygon(
    CreatePolygon event,
    Emitter<PolygonsState> emit,
  ) async {
    try {
      if (_tapPositions.length < 3) {
        emit(const PolygonsError(error: 'Need at least 3 points to create a polygon'));
        return;
      }

      // Build a closed ring
      final ring = _tapPositions.map((p) => [p.lng, p.lat]).toList()
        ..add([_tapPositions.first.lng, _tapPositions.first.lat]);

      final featureName = _generateRandomName();

      final feature = {
        "type": "Feature",
        "id": featureName,
        "geometry": {
          "type": "Polygon",
          "coordinates": [ring],
        },
        "properties": {"name": featureName},
      };

      _polygonFeatures.add(feature);

      // Update the GeoJSON source
      final fc = {
        "type": "FeatureCollection",
        "features": _polygonFeatures,
      };
      await _geoJsonSource?.updateGeoJSON(json.encode(fc));

      // Clear annotations and tap positions
      await event.pointAnnotationManager.deleteAll();
      _tapPositions.clear();

      emit(PolygonCreated(
        tapPositions: List.from(_tapPositions),
        polygonFeatures: List.from(_polygonFeatures),
        polygonName: featureName,
      ));
    } catch (e) {
      emit(PolygonsError(error: 'Failed to create polygon: $e'));
    }
  }

  Future<void> _onTapPolygon(
    TapPolygon event,
    Emitter<PolygonsState> emit,
  ) async {
    emit(PolygonTapped(
      tapPositions: List.from(_tapPositions),
      polygonFeatures: List.from(_polygonFeatures),
      tappedPolygon: event.feature,
    ));
  }

  Future<void> _onClearAll(
    ClearAll event,
    Emitter<PolygonsState> emit,
  ) async {
    try {
      // Clear annotations
      if (event.pointAnnotationManager != null) {
        await event.pointAnnotationManager!.deleteAll();
      }

      // Clear polygons from map
      if (_geoJsonSource != null) {
        final emptyCollection = {"type": "FeatureCollection", "features": []};
        await _geoJsonSource!.updateGeoJSON(json.encode(emptyCollection));
      }

      // Clear local data
      _tapPositions.clear();
      _polygonFeatures.clear();

      emit(PolygonsCleared());
    } catch (e) {
      emit(PolygonsError(error: 'Failed to clear all: $e'));
    }
  }

  String _generateRandomName() {
    final adj = _adjectives[_rnd.nextInt(_adjectives.length)];
    final noun = _nouns[_rnd.nextInt(_nouns.length)];
    final suffix = _rnd.nextInt(1000);
    return '$adj $noun $suffix';
  }
}