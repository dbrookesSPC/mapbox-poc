import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';

abstract class AnnotationsState extends Equatable {
  const AnnotationsState();

  @override
  List<Object?> get props => [];
}

class AnnotationsInitial extends AnnotationsState {}

class AnnotationsLoading extends AnnotationsState {}

class AnnotationsReady extends AnnotationsState {
  final List<GeoCoordinates> tapPositions;

  const AnnotationsReady({required this.tapPositions});

  @override
  List<Object> get props => [tapPositions];
}

class AnnotationAdded extends AnnotationsState {
  final List<GeoCoordinates> tapPositions;
  final GeoCoordinates newPosition;

  const AnnotationAdded({
    required this.tapPositions,
    required this.newPosition,
  });

  @override
  List<Object> get props => [tapPositions, newPosition];
}

class AnnotationsCleared extends AnnotationsState {}

class AnnotationsError extends AnnotationsState {
  final String error;

  const AnnotationsError({required this.error});

  @override
  List<Object> get props => [error];
}