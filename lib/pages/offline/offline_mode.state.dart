import 'package:equatable/equatable.dart';

abstract class OfflineState extends Equatable {
  const OfflineState();

  @override
  List<Object?> get props => [];
}

class OfflineInitial extends OfflineState {}

class OfflineLoading extends OfflineState {}

class OfflineDownloadProgress extends OfflineState {
  final double styleProgress;
  final double tileProgress;
  final String currentTask;

  const OfflineDownloadProgress({
    required this.styleProgress,
    required this.tileProgress,
    required this.currentTask,
  });

  @override
  List<Object> get props => [styleProgress, tileProgress, currentTask];
}

class OfflineDownloadComplete extends OfflineState {
  final String message;

  const OfflineDownloadComplete({required this.message});

  @override
  List<Object> get props => [message];
}

class OfflineError extends OfflineState {
  final String error;

  const OfflineError({required this.error});

  @override
  List<Object> get props => [error];
}