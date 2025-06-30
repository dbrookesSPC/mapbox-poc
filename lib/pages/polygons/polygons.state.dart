import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';

abstract class PolygonsState extends Equatable {
  const PolygonsState();

  @override
  List<Object?> get props => [];
}

class PolygonsInitial extends PolygonsState {}

class PolygonsLoading extends PolygonsState {}

class PolygonsReady extends PolygonsState {
  final List<GeoCoordinates> tapPositions;
  final List<PolygonData> polygonFeatures;

  const PolygonsReady({
    required this.tapPositions,
    required this.polygonFeatures,
  });

  @override
  List<Object> get props => [tapPositions, polygonFeatures];
}

class PointAdded extends PolygonsState {
  final List<GeoCoordinates> tapPositions;
  final GeoCoordinates newPosition;
  final List<PolygonData> polygonFeatures;

  const PointAdded({
    required this.tapPositions,
    required this.newPosition,
    required this.polygonFeatures,
  });

  @override
  List<Object> get props => [tapPositions, newPosition, polygonFeatures];
}

class PolygonCreated extends PolygonsState {
  final List<GeoCoordinates> tapPositions;
  final List<PolygonData> polygonFeatures;
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
  final List<GeoCoordinates> tapPositions;
  final List<PolygonData> polygonFeatures;
  final PolygonData tappedPolygon;

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

// Helper class to store polygon data
class PolygonData extends Equatable {
  final String id;
  final String name;
  final List<GeoCoordinates> coordinates;

  const PolygonData({
    required this.id,
    required this.name,
    required this.coordinates,
  });

  @override
  List<Object> get props => [id, name, coordinates];
}