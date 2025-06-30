import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

abstract class PolygonsState extends Equatable {
  const PolygonsState();

  @override
  List<Object?> get props => [];
}

class PolygonsInitial extends PolygonsState {}

class PolygonsLoading extends PolygonsState {}

class PolygonsReady extends PolygonsState {
  final List<Position> tapPositions;
  final List<Map<String, dynamic>> polygonFeatures;

  const PolygonsReady({
    required this.tapPositions,
    required this.polygonFeatures,
  });

  @override
  List<Object> get props => [tapPositions, polygonFeatures];
}

class PointAdded extends PolygonsState {
  final List<Position> tapPositions;
  final Position newPosition;
  final List<Map<String, dynamic>> polygonFeatures;

  const PointAdded({
    required this.tapPositions,
    required this.newPosition,
    required this.polygonFeatures,
  });

  @override
  List<Object> get props => [tapPositions, newPosition, polygonFeatures];
}

class PolygonCreated extends PolygonsState {
  final List<Position> tapPositions;
  final List<Map<String, dynamic>> polygonFeatures;
  final String polygonName;

  const PolygonCreated({
    required this.tapPositions,
    required this.polygonFeatures,
    required this.polygonName,
  });

  @override
  List<Object> get props => [tapPositions, polygonFeatures, polygonName];
}

class PolygonTapped extends PolygonsState {
  final List<Position> tapPositions;
  final List<Map<String, dynamic>> polygonFeatures;
  final Map<String, dynamic> tappedPolygon;

  const PolygonTapped({
    required this.tapPositions,
    required this.polygonFeatures,
    required this.tappedPolygon,
  });

  @override
  List<Object> get props => [tapPositions, polygonFeatures, tappedPolygon];
}

class PolygonsCleared extends PolygonsState {}

class PolygonsError extends PolygonsState {
  final String error;

  const PolygonsError({required this.error});

  @override
  List<Object> get props => [error];
}