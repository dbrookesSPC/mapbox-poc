import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'polygons.events.dart';
import 'polygons.state.dart';

class PolygonsBloc extends Bloc<PolygonsEvent, PolygonsState> {
  MapImage? _annotationImage;
  final List<GeoCoordinates> _tapPositions = [];
  final List<PolygonData> _polygonFeatures = [];
  final List<MapMarker> _pointMarkers = [];
  final List<MapPolygon> _mapPolygons = [];
  final Random _rnd = Random();

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

      // Load the annotation image for HERE Maps
      int imageWidth = 120;
      int imageHeight = 120;
      _annotationImage = MapImage.withFilePathAndWidthAndHeight("assets/ano.png", imageWidth, imageHeight);

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

      final coordinates = GeoCoordinates(event.lat, event.lng);

      // Create HERE map marker for the point
      final mapMarker = MapMarker(coordinates, _annotationImage!);
      
      // Add to the map scene
      event.hereMapController.mapScene.addMapMarker(mapMarker);
      
      // Add to our local lists
      _tapPositions.add(coordinates);
      _pointMarkers.add(mapMarker);

      emit(PointAdded(
        tapPositions: List.from(_tapPositions),
        newPosition: coordinates,
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

      final polygonName = _generateRandomName();
      
      // Create MapPolygon using HERE SDK
      MapPolygon? mapPolygon = _createMapPolygon(_tapPositions);
      
      if (mapPolygon != null) {
        // Add polygon to map
        event.hereMapController.mapScene.addMapPolygon(mapPolygon);
        _mapPolygons.add(mapPolygon);

        // Store polygon data
        final polygonData = PolygonData(
          id: polygonName,
          name: polygonName,
          coordinates: List.from(_tapPositions),
        );
        _polygonFeatures.add(polygonData);

        // Clear point markers from map
        for (MapMarker marker in _pointMarkers) {
          event.hereMapController.mapScene.removeMapMarker(marker);
        }
        _pointMarkers.clear();
        _tapPositions.clear();

        emit(PolygonCreated(
          tapPositions: List.from(_tapPositions),
          polygonFeatures: List.from(_polygonFeatures),
          polygonName: polygonName,
        ));
      } else {
        emit(const PolygonsError(error: 'Failed to create polygon geometry'));
      }
    } catch (e) {
      emit(PolygonsError(error: 'Failed to create polygon: $e'));
    }
  }

  MapPolygon? _createMapPolygon(List<GeoCoordinates> coordinates) {
    try {
      // Create polygon from coordinates
      GeoPolygon geoPolygon = GeoPolygon(coordinates);
      
      // Use a semi-transparent fill color (similar to the original)
      Color fillColor = const Color.fromARGB(151, 250, 0, 0);
      MapPolygon mapPolygon = MapPolygon(geoPolygon, fillColor);
      
      return mapPolygon;
    } catch (e) {
      // Less than three vertices or invalid geometry or any other error
      print('Error creating polygon: $e');
      return null;
    }
  }

  Future<void> _onTapPolygon(
    TapPolygon event,
    Emitter<PolygonsState> emit,
  ) async {
    emit(PolygonTapped(
      tapPositions: List.from(_tapPositions),
      polygonFeatures: List.from(_polygonFeatures),
      tappedPolygon: event.polygonData,
    ));
  }

  Future<void> _onClearAll(
    ClearAll event,
    Emitter<PolygonsState> emit,
  ) async {
    try {
      if (event.hereMapController != null) {
        // Clear point markers
        for (MapMarker marker in _pointMarkers) {
          event.hereMapController!.mapScene.removeMapMarker(marker);
        }
        
        // Clear polygons
        for (MapPolygon polygon in _mapPolygons) {
          event.hereMapController!.mapScene.removeMapPolygon(polygon);
        }
      }

      // Clear local data
      _tapPositions.clear();
      _polygonFeatures.clear();
      _pointMarkers.clear();
      _mapPolygons.clear();

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