import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

abstract class AnnotationsEvent extends Equatable {
  const AnnotationsEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAnnotations extends AnnotationsEvent {
  final PointAnnotationManager pointAnnotationManager;

  const InitializeAnnotations({required this.pointAnnotationManager});

  @override
  List<Object> get props => [pointAnnotationManager];
}

class AddAnnotation extends AnnotationsEvent {
  final double lng;
  final double lat;
  final PointAnnotationManager pointAnnotationManager;

  const AddAnnotation({
    required this.lng,
    required this.lat,
    required this.pointAnnotationManager,
  });

  @override
  List<Object> get props => [lng, lat, pointAnnotationManager];
}

class ClearAnnotations extends AnnotationsEvent {
  final PointAnnotationManager? pointAnnotationManager;

  const ClearAnnotations({this.pointAnnotationManager});

  @override
  List<Object?> get props => [pointAnnotationManager];
}