import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';

abstract class ClustersState extends Equatable {
  const ClustersState();

  @override
  List<Object?> get props => [];
}

class ClustersInitial extends ClustersState {}

class ClustersLoading extends ClustersState {}

class ClustersLoaded extends ClustersState {
  final List<MapMarkerCluster> clusters;
  final int totalPoints;

  const ClustersLoaded({
    required this.clusters,
    required this.totalPoints,
  });

  @override
  List<Object> get props => [clusters, totalPoints];
}

class ClusterTapped extends ClustersState {
  final List<MapMarker> clusterMarkers;
  final GeoCoordinates center;
  final int pointCount;

  const ClusterTapped({
    required this.clusterMarkers,
    required this.center,
    required this.pointCount,
  });

  @override
  List<Object> get props => [clusterMarkers, center, pointCount];
}

class ClustersError extends ClustersState {
  final String error;

  const ClustersError({required this.error});

  @override
  List<Object> get props => [error];
}