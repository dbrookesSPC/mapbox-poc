import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/maploader.dart';

abstract class OfflineState extends Equatable {
  const OfflineState();

  @override
  List<Object?> get props => [];
}

class OfflineInitial extends OfflineState {}

class OfflineLoading extends OfflineState {}

class OfflineRegionsLoaded extends OfflineState {
  final List<Region> regions;

  const OfflineRegionsLoaded({required this.regions});

  @override
  List<Object> get props => [regions];
}

class OfflineDownloadProgress extends OfflineState {
  final int percentage;
  final String currentTask;
  final RegionId? regionId;

  const OfflineDownloadProgress({
    required this.percentage,
    required this.currentTask,
    this.regionId,
  });

  @override
  List<Object?> get props => [percentage, currentTask, regionId];
}

class OfflineDownloadComplete extends OfflineState {
  final String message;
  final List<InstalledRegion> installedRegions;

  const OfflineDownloadComplete({
    required this.message,
    required this.installedRegions,
  });

  @override
  List<Object> get props => [message, installedRegions];
}

class OfflineSearchResults extends OfflineState {
  final List<String> results;
  final String query;

  const OfflineSearchResults({
    required this.results,
    required this.query,
  });

  @override
  List<Object> get props => [results, query];
}

class OfflineError extends OfflineState {
  final String error;

  const OfflineError({required this.error});

  @override
  List<Object> get props => [error];
}