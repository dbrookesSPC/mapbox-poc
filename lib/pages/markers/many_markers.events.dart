import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

abstract class ManyMarkersEvent extends Equatable {
  const ManyMarkersEvent();

  @override
  List<Object?> get props => [];
}

class GenerateMarkers extends ManyMarkersEvent {
  final double centerLng;
  final double centerLat;
  final int markerCount;
  final double spread;
  final MapboxMap mapboxMap;

  const GenerateMarkers({
    required this.centerLng,
    required this.centerLat,
    required this.mapboxMap,
    this.markerCount = 15000,
    this.spread = 20.0,
  });

  @override
  List<Object> get props => [centerLng, centerLat, mapboxMap, markerCount, spread];
}

class ClearMarkers extends ManyMarkersEvent {
  final MapboxMap? mapboxMap;

  const ClearMarkers({this.mapboxMap});

  @override
  List<Object?> get props => [mapboxMap];
}