import 'package:equatable/equatable.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/core.dart';

abstract class OfflineEvent extends Equatable {
  const OfflineEvent();

  @override
  List<Object?> get props => [];
}

class InitializeOfflineManager extends OfflineEvent {
  final HereMapController hereMapController;

  const InitializeOfflineManager({required this.hereMapController});

  @override
  List<Object> get props => [hereMapController];
}

class LoadAvailableRegions extends OfflineEvent {}

class DownloadRegion extends OfflineEvent {
  final String regionName;

  const DownloadRegion({required this.regionName});

  @override
  List<Object> get props => [regionName];
}

class DownloadCurrentViewArea extends OfflineEvent {
  final HereMapController hereMapController;

  const DownloadCurrentViewArea({required this.hereMapController});

  @override
  List<Object> get props => [hereMapController];
}

class SearchOffline extends OfflineEvent {
  final String query;
  final HereMapController hereMapController;

  const SearchOffline({
    required this.query,
    required this.hereMapController,
  });

  @override
  List<Object> get props => [query, hereMapController];
}

class DeleteAllRegions extends OfflineEvent {}

class ToggleOfflineMode extends OfflineEvent {
  final bool isOffline;

  const ToggleOfflineMode({required this.isOffline});

  @override
  List<Object> get props => [isOffline];
}

class ClearCache extends OfflineEvent {}