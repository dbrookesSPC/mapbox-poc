import 'package:equatable/equatable.dart';
import 'package:here_sdk/mapview.dart';

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
  final HereMapController hereMapController;

  const GenerateMarkers({
    required this.centerLng,
    required this.centerLat,
    required this.hereMapController,
    this.markerCount = 15000,
    this.spread = 20.0,
  });

  @override
  List<Object> get props => [centerLng, centerLat, hereMapController, markerCount, spread];
}

class GenerateHerdWidgets extends ManyMarkersEvent {
  final double centerLng;
  final double centerLat;
  final int widgetCount;
  final double spread;
  final HereMapController hereMapController;

  const GenerateHerdWidgets({
    required this.centerLng,
    required this.centerLat,
    required this.hereMapController,
    this.widgetCount = 1000,
    this.spread = 20.0,
  });

  @override
  List<Object> get props => [centerLng, centerLat, hereMapController, widgetCount, spread];
}

class ClearMarkers extends ManyMarkersEvent {
  final HereMapController? hereMapController;

  const ClearMarkers({this.hereMapController});

  @override
  List<Object?> get props => [hereMapController];
}