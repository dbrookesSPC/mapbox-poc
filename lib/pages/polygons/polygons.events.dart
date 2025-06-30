import 'package:equatable/equatable.dart';
import 'package:here_sdk/mapview.dart';
import 'polygons.state.dart'; // Import to access PolygonData

abstract class PolygonsEvent extends Equatable {
  const PolygonsEvent();

  @override
  List<Object?> get props => [];
}

class InitializePolygons extends PolygonsEvent {
  final HereMapController hereMapController;

  const InitializePolygons({required this.hereMapController});

  @override
  List<Object> get props => [hereMapController];
}

class AddPoint extends PolygonsEvent {
  final double lng;
  final double lat;
  final HereMapController hereMapController;

  const AddPoint({
    required this.lng,
    required this.lat,
    required this.hereMapController,
  });

  @override
  List<Object> get props => [lng, lat, hereMapController];
}

class CreatePolygon extends PolygonsEvent {
  final HereMapController hereMapController;

  const CreatePolygon({required this.hereMapController});

  @override
  List<Object> get props => [hereMapController];
}

class TapPolygon extends PolygonsEvent {
  final PolygonData polygonData;

  const TapPolygon({required this.polygonData});

  @override
  List<Object> get props => [polygonData];
}

class ClearAll extends PolygonsEvent {
  final HereMapController? hereMapController;

  const ClearAll({this.hereMapController});

  @override
  List<Object?> get props => [hereMapController];
}