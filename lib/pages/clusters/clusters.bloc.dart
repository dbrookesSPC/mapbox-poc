import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:http/http.dart' as http;
import 'clusters.events.dart';
import 'clusters.state.dart';

class ClustersBloc extends Bloc<ClustersEvent, ClustersState> {
  MapImage? _clusterImage;
  MapImage? _pointImage;
  final List<MapMarkerCluster> _clusters = [];
  final List<MapMarker> _allMarkers = [];

  ClustersBloc() : super(ClustersInitial()) {
    on<LoadClusters>(_onLoadClusters);
    on<TapCluster>(_onTapCluster);
    on<ClearClusters>(_onClearClusters);
  }

  Future<void> _onLoadClusters(
    LoadClusters event,
    Emitter<ClustersState> emit,
  ) async {
    try {
      emit(ClustersLoading());

      // Load cluster source JSON (Mapbox configuration)
      final sourceJson = await rootBundle.loadString('assets/cluster/cluster_source.json');
      final sourceConfig = json.decode(sourceJson);

      // Extract the data URL from the Mapbox configuration
      String dataUrl;
      if (sourceConfig is Map<String, dynamic> && sourceConfig.containsKey('data')) {
        dataUrl = sourceConfig['data'];
      } else {
        throw Exception('No data URL found in cluster source configuration');
      }

      print('Fetching earthquake data from: $dataUrl');

      // Fetch the actual earthquake data from the URL
      final response = await http.get(Uri.parse(dataUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch earthquake data: ${response.statusCode}');
      }

      final earthquakeData = json.decode(response.body);
      print('Fetched earthquake data: ${earthquakeData.runtimeType}');

      // Create marker images if not already created
      if (_clusterImage == null) {
        Uint8List imagePixelData = await _loadFileAsUint8List('assets/ano.png');
        _clusterImage = MapImage.withPixelDataAndImageFormat(imagePixelData, ImageFormat.png);
      }
      
      if (_pointImage == null) {
        Uint8List pointImageData = await _loadFileAsUint8List('assets/ano.png');
        _pointImage = MapImage.withPixelDataAndImageFormat(pointImageData, ImageFormat.png);
      }

      // Create cluster counter style
      MapMarkerClusterCounterStyle counterStyle = MapMarkerClusterCounterStyle();
      counterStyle.textColor = Colors.white;
      counterStyle.fontSize = 16;
      counterStyle.maxCountNumber = 99;
      counterStyle.aboveMaxText = "99+";

      // Create map marker cluster with counter
      MapMarkerCluster mapMarkerCluster = MapMarkerCluster.WithCounter(
        MapMarkerClusterImageStyle(_clusterImage!), 
        counterStyle
      );

      // Add cluster to map scene first
      event.hereMapController.mapScene.addMapMarkerCluster(mapMarkerCluster);

      // Parse the GeoJSON earthquake data
      if (earthquakeData is! Map<String, dynamic>) {
        throw Exception('Invalid earthquake data format');
      }

      final features = earthquakeData['features'] as List<dynamic>?;
      if (features == null) {
        throw Exception('No features found in earthquake data');
      }

      print('Found ${features.length} earthquake features to process');

      final List<MapMarker> markers = [];

      for (int i = 0; i < features.length; i++) {
        try {
          final feature = features[i] as Map<String, dynamic>;
          final geometry = feature['geometry'] as Map<String, dynamic>?;
          final properties = feature['properties'] as Map<String, dynamic>?;
          final featureId = feature['id'];
          
          if (geometry == null) {
            print('Skipping feature $i: no geometry');
            continue;
          }
          
          final coordinates = geometry['coordinates'] as List<dynamic>?;
          if (coordinates == null || coordinates.length < 2) {
            print('Skipping feature $i: invalid coordinates');
            continue;
          }
          
          final longitude = _parseToDouble(coordinates[0]);
          final latitude = _parseToDouble(coordinates[1]);
          
          if (longitude == null || latitude == null) {
            print('Skipping feature $i: could not parse coordinates [${coordinates[0]}, ${coordinates[1]}]');
            continue;
          }
          
          // Validate coordinate ranges
          if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
            print('Skipping feature $i: coordinates out of range [$latitude, $longitude]');
            continue;
          }
          
          final geoCoordinates = GeoCoordinates(latitude, longitude);
          final mapMarker = MapMarker(geoCoordinates, _pointImage!);
          
          // Store feature properties as metadata
          Metadata metadata = Metadata();
          
          // Safe ID parsing
          if (featureId != null) {
            metadata.setString("key_cluster", "earthquake_$featureId");
          } else {
            metadata.setString("key_cluster", "earthquake_$i");
          }
          
          // Safe property parsing
          if (properties != null) {
            if (properties.containsKey('mag')) {
              final mag = properties['mag'];
              metadata.setString("magnitude", mag?.toString() ?? "unknown");
            }
            
            if (properties.containsKey('place')) {
              final place = properties['place'];
              metadata.setString("place", place?.toString() ?? "unknown");
            }
            
            if (properties.containsKey('time')) {
              final time = properties['time'];
              metadata.setString("time", time?.toString() ?? "unknown");
            }
          }
          
          mapMarker.metadata = metadata;
          markers.add(mapMarker);
          
          // Add marker to cluster
          mapMarkerCluster.addMapMarker(mapMarker);
          
        } catch (e) {
          print('Error processing earthquake feature $i: $e');
          continue;
        }
      }

      print('Successfully processed ${markers.length} earthquake markers');

      _allMarkers.clear();
      _allMarkers.addAll(markers);
      
      _clusters.clear();
      _clusters.add(mapMarkerCluster);

      emit(ClustersLoaded(
        clusters: List.from(_clusters),
        totalPoints: markers.length,
      ));
    } catch (e) {
      print('Full error details: $e');
      emit(ClustersError(error: 'Failed to load clusters: $e'));
    }
  }

  Future<Uint8List> _loadFileAsUint8List(String assetPath) async {
    ByteData fileData = await rootBundle.load(assetPath);
    return Uint8List.view(fileData.buffer);
  }

  Future<void> _onTapCluster(
    TapCluster event,
    Emitter<ClustersState> emit,
  ) async {
    emit(ClusterTapped(
      clusterMarkers: event.markers,
      center: event.center,
      pointCount: event.markers.length,
    ));
  }

  Future<void> _onClearClusters(
    ClearClusters event,
    Emitter<ClustersState> emit,
  ) async {
    try {
      if (event.hereMapController != null) {
        // Remove all clusters from map
        for (final cluster in _clusters) {
          event.hereMapController!.mapScene.removeMapMarkerCluster(cluster);
        }
      }
      
      _clusters.clear();
      _allMarkers.clear();
      
      emit(ClustersInitial());
    } catch (e) {
      emit(ClustersError(error: 'Failed to clear clusters: $e'));
    }
  }

  // Helper method to safely parse numeric values
  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Could not parse string to double: $value');
        return null;
      }
    }
    print('Unknown numeric type: ${value.runtimeType} - $value');
    return null;
  }
}