import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'annotations.events.dart';
import 'annotations.state.dart';

class AnnotationsBloc extends Bloc<AnnotationsEvent, AnnotationsState> {
  MapImage? _annotationImage;
  final List<GeoCoordinates> _tapPositions = [];
  final List<MapMarker> _mapMarkers = [];

  AnnotationsBloc() : super(AnnotationsInitial()) {
    on<InitializeAnnotations>(_onInitializeAnnotations);
    on<AddAnnotation>(_onAddAnnotation);
    on<ClearAnnotations>(_onClearAnnotations);
  }

  Future<void> _onInitializeAnnotations(
    InitializeAnnotations event,
    Emitter<AnnotationsState> emit,
  ) async {
    try {
      emit(AnnotationsLoading());
      
      // Load the annotation image for HERE Maps
      int imageWidth = 120;
      int imageHeight = 120;
      _annotationImage = MapImage.withFilePathAndWidthAndHeight("assets/ano.png", imageWidth, imageHeight);
      
      emit(AnnotationsReady(tapPositions: List.from(_tapPositions)));
    } catch (e) {
      emit(AnnotationsError(error: 'Failed to initialize annotations: $e'));
    }
  }

  Future<void> _onAddAnnotation(
    AddAnnotation event,
    Emitter<AnnotationsState> emit,
  ) async {
    try {
      if (_annotationImage == null) {
        emit(const AnnotationsError(error: 'Annotation image not loaded'));
        return;
      }

      final coordinates = GeoCoordinates(event.lat, event.lng);
      
      // Create HERE map marker
      final mapMarker = MapMarker(coordinates, _annotationImage!);
      
      // Add to the map scene
      event.hereMapController.mapScene.addMapMarker(mapMarker);
      
      // Add to our local lists
      _tapPositions.add(coordinates);
      _mapMarkers.add(mapMarker);

      emit(AnnotationAdded(
        tapPositions: List.from(_tapPositions),
        newPosition: coordinates,
      ));
    } catch (e) {
      emit(AnnotationsError(error: 'Failed to add annotation: $e'));
    }
  }

  Future<void> _onClearAnnotations(
    ClearAnnotations event,
    Emitter<AnnotationsState> emit,
  ) async {
    try {
      if (event.hereMapController != null) {
        // Remove all markers from the map scene
        for (MapMarker marker in _mapMarkers) {
          event.hereMapController!.mapScene.removeMapMarker(marker);
        }
      }
      
      // Clear our local lists
      _tapPositions.clear();
      _mapMarkers.clear();

      emit(AnnotationsCleared());
    } catch (e) {
      emit(AnnotationsError(error: 'Failed to clear annotations: $e'));
    }
  }

  List<GeoCoordinates> get tapPositions => List.from(_tapPositions);
}