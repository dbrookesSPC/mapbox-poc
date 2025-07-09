import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';

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
  final String type; // "markers" or "widgets"

  const ManyMarkersGenerating({
    required this.generatedCount,
    required this.totalCount,
    required this.type,
  });

  @override
  List<Object> get props => [generatedCount, totalCount, type];
}

class ManyMarkersLoaded extends ManyMarkersState {
  final List<GeoCoordinates> markerPositions;
  final int markerCount;
  final String type; // "markers" or "widgets"

  const ManyMarkersLoaded({
    required this.markerPositions,
    required this.markerCount,
    required this.type,
  });

  @override
  List<Object> get props => [markerPositions, markerCount, type];
}

class ManyMarkersError extends ManyMarkersState {
  final String error;

  const ManyMarkersError({required this.error});

  @override
  List<Object> get props => [error];
}

class ManyMarkersElementsLoaded extends ManyMarkersState {
  final int polygonCount;
  final int markerCount;
  final int widgetCount;
  final int lineCount;

  const ManyMarkersElementsLoaded({
    required this.polygonCount,
    required this.markerCount,
    required this.widgetCount,
    required this.lineCount,
  });

  @override
  List<Object> get props => [polygonCount, markerCount, widgetCount, lineCount];
}
