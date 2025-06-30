import 'package:equatable/equatable.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/core.dart';

abstract class ClustersEvent extends Equatable {
  const ClustersEvent();

  @override
  List<Object?> get props => [];
}

class LoadClusters extends ClustersEvent {
  final HereMapController hereMapController;

  const LoadClusters({required this.hereMapController});

  @override
  List<Object> get props => [hereMapController];
}

class TapCluster extends ClustersEvent {
  final GeoCoordinates center;
  final List<MapMarker> markers;

  const TapCluster({
    required this.center,
    required this.markers,
  });

  @override
  List<Object> get props => [center, markers];
}

class ClearClusters extends ClustersEvent {
  final HereMapController? hereMapController;

  const ClearClusters({this.hereMapController});

  @override
  List<Object?> get props => [hereMapController];
}