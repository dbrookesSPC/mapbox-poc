import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

abstract class PolygonsEvent extends Equatable {
  const PolygonsEvent();

  @override
  List<Object?> get props => [];
}

class InitializePolygons extends PolygonsEvent {
  final MapboxMap mapboxMap;
  final PointAnnotationManager pointAnnotationManager;

  const InitializePolygons({
    required this.mapboxMap,
    required this.pointAnnotationManager,
  });

  @override
  List<Object> get props => [mapboxMap, pointAnnotationManager];
}

class AddPoint extends PolygonsEvent {
  final double lng;
  final double lat;
  final PointAnnotationManager pointAnnotationManager;

  const AddPoint({
    required this.lng,
    required this.lat,
    required this.pointAnnotationManager,
  });

  @override
  List<Object> get props => [lng, lat, pointAnnotationManager];
}

class CreatePolygon extends PolygonsEvent {
  final MapboxMap mapboxMap;
  final PointAnnotationManager pointAnnotationManager;

  const CreatePolygon({
    required this.mapboxMap,
    required this.pointAnnotationManager,
  });

  @override
  List<Object> get props => [mapboxMap, pointAnnotationManager];
}

class TapPolygon extends PolygonsEvent {
  final Map<String, dynamic> feature;

  const TapPolygon({required this.feature});

  @override
  List<Object> get props => [feature];
}

class ClearAll extends PolygonsEvent {
  final MapboxMap? mapboxMap;
  final PointAnnotationManager? pointAnnotationManager;

  const ClearAll({this.mapboxMap, this.pointAnnotationManager});

  @override
  List<Object?> get props => [mapboxMap, pointAnnotationManager];
}