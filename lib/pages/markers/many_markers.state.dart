import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

abstract class ManyMarkersState extends Equatable {
  const ManyMarkersState();

  @override
  List<Object?> get props => [];
}

class ManyMarkersInitial extends ManyMarkersState {}

class ManyMarkersLoading extends ManyMarkersState {}

class ManyMarkersGenerating extends ManyMarkersState {
  final int generatedCount;
  final int totalCount;

  const ManyMarkersGenerating({
    required this.generatedCount,
    required this.totalCount,
  });

  @override
  List<Object> get props => [generatedCount, totalCount];
}

class ManyMarkersLoaded extends ManyMarkersState {
  final List<PointAnnotation> markers;
  final int markerCount;

  const ManyMarkersLoaded({
    required this.markers,
    required this.markerCount,
  });

  @override
  List<Object> get props => [markers, markerCount];
}

class ManyMarkersError extends ManyMarkersState {
  final String error;

  const ManyMarkersError({required this.error});

  @override
  List<Object> get props => [error];
}