import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'annotations.events.dart';
import 'annotations.state.dart';

class AnnotationsBloc extends Bloc<AnnotationsEvent, AnnotationsState> {
  Uint8List? _annotationImage;
  final List<Position> _tapPositions = [];

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
      
      // Load the annotation image
      final ByteData bytes = await rootBundle.load('assets/ano.png');
      _annotationImage = bytes.buffer.asUint8List();
      
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

      emit(AnnotationAdded(
        tapPositions: List.from(_tapPositions),
        newPosition: position,
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
      if (event.pointAnnotationManager != null) {
        // Delete all annotations from the map
        await event.pointAnnotationManager!.deleteAll();
      }
      
      // Clear our local list
      _tapPositions.clear();

      emit(AnnotationsCleared());
    } catch (e) {
      emit(AnnotationsError(error: 'Failed to clear annotations: $e'));
    }
  }

  List<Position> get tapPositions => List.from(_tapPositions);
}