import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

abstract class ManyMarkersEvent extends Equatable {
  const ManyMarkersEvent();

  @override
  List<Object?> get props => [];
}

class GenerateMarkers extends ManyMarkersEvent {
  final int count;
  final Point? centerCoordinate;
  final double? zoom;

  const GenerateMarkers({
    required this.count,
    this.centerCoordinate,
    this.zoom,
  });

  @override
  List<Object?> get props => [count, centerCoordinate, zoom];
}

class ClearMarkers extends ManyMarkersEvent {}

class InitializeAnnotationManager extends ManyMarkersEvent {
  final PointAnnotationManager annotationManager;

  const InitializeAnnotationManager({required this.annotationManager});

  @override
  List<Object> get props => [annotationManager];
}