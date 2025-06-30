import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class SimpleMapState extends State<StatefulWidget> {
  SimpleMapState();
  MapboxMap? mapboxMap;

  GeoJsonSource? geoJsonSource;
  PointAnnotationManager? pointAnnotationManager;
  CameraViewportState camera = CameraViewportState(
    center: Point(coordinates: Position(-3.48, 36.76)),
    zoom: 8,
    bearing: 0,
    pitch: 70,
  );
  
  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    pointAnnotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    onMapCreated();
  }
onMapCreated() async {
    // You can add your own map created logic here
    // For example, you can initialize sources, layers, or annotations
    // await mapboxMap.setStyleUri(MapboxStyles.STANDARD_SATELLITE);
    // await mapboxMap.setCamera(camera);
    // print("Map created with camera: $camera");
  }
  onStyleLoaded(StyleLoadedEventData styleEvent) async {
    // You can add your own style loaded logic here
  }
  onResourceRequest(ResourceEventData resourceEventData) {
    final url = resourceEventData.request.url;
    // print("onResourceRequest");
    // print("url: $url");
  }

  Future<void> onTapListener(MapContentGestureContext context) async {
    // You can add your own tap listener logic here
  }
  Future<void> onLongTapListener(MapContentGestureContext context) async {
    // You can add your own long tap listener logic here
  }
  @override
  Widget build(BuildContext context) {
    return MapWidget(
      styleUri: MapboxStyles.STANDARD_SATELLITE,
      viewport: camera,
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: onStyleLoaded,
      onResourceRequestListener: onResourceRequest,
      onTapListener: onTapListener,
      onLongTapListener: onLongTapListener,
    );
  }
}
