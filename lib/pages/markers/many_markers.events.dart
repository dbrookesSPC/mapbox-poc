import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';
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

class AddPolygon extends ManyMarkersEvent {
  final List<GeoCoordinates> points;
  final HereMapController hereMapController;

  const AddPolygon(this.points, this.hereMapController);

  @override
  List<Object> get props => [points, hereMapController];
}

class AddMarker extends ManyMarkersEvent {
  final GeoCoordinates position;
  final HereMapController hereMapController;
  final String? markerType;

  const AddMarker(this.position, this.hereMapController, {this.markerType});

  @override
  List<Object?> get props => [position, hereMapController, markerType];
}

class AddWidget extends ManyMarkersEvent {
  final GeoCoordinates position;
  final HereMapController hereMapController;

  const AddWidget(this.position, this.hereMapController);

  @override
  List<Object> get props => [position, hereMapController];
}

class AddLine extends ManyMarkersEvent {
  final GeoCoordinates start;
  final GeoCoordinates end;
  final HereMapController hereMapController;

  const AddLine(this.start, this.end, this.hereMapController);

  @override
  List<Object> get props => [start, end, hereMapController];
}

class LoadJSONElementsComplete extends ManyMarkersEvent {
  final int polygonCount;
  final int markerCount;
  final int widgetCount;
  final int lineCount;

  const LoadJSONElementsComplete({
    required this.polygonCount,
    required this.markerCount,
    required this.widgetCount,
    required this.lineCount,
  });

  @override
  List<Object> get props => [polygonCount, markerCount, widgetCount, lineCount];
}
