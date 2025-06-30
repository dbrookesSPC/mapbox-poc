import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

abstract class OfflineEvent extends Equatable {
  const OfflineEvent();

  @override
  List<Object?> get props => [];
}

class InitializeOfflineManager extends OfflineEvent {}

class SaveCurrentViewOffline extends OfflineEvent {
  final CameraState cameraState;

  const SaveCurrentViewOffline({required this.cameraState});

  @override
  List<Object> get props => [cameraState];
}