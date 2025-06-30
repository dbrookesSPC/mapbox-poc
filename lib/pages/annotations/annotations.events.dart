import 'package:equatable/equatable.dart';
import 'package:here_sdk/mapview.dart';

abstract class AnnotationsEvent extends Equatable {
  const AnnotationsEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAnnotations extends AnnotationsEvent {
  final HereMapController hereMapController;

  const InitializeAnnotations({required this.hereMapController});

  @override
  List<Object> get props => [hereMapController];
}

class AddAnnotation extends AnnotationsEvent {
  final double lng;
  final double lat;
  final HereMapController hereMapController;

  const AddAnnotation({
    required this.lng,
    required this.lat,
    required this.hereMapController,
  });

  @override
  List<Object> get props => [lng, lat, hereMapController];
}

class ClearAnnotations extends AnnotationsEvent {
  final HereMapController? hereMapController;

  const ClearAnnotations({this.hereMapController});

  @override
  List<Object?> get props => [hereMapController];
}