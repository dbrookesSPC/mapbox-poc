import 'package:equatable/equatable.dart';

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
  final Map<String, dynamic> geoJsonData;
  final int markerCount;

  const ManyMarkersLoaded({
    required this.geoJsonData,
    required this.markerCount,
  });

  @override
  List<Object> get props => [geoJsonData, markerCount];
}

class ManyMarkersError extends ManyMarkersState {
  final String error;

  const ManyMarkersError({required this.error});

  @override
  List<Object> get props => [error];
}