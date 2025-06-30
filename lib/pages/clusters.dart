import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:maps_poc/basicMap.dart';
import 'package:maps_poc/page.dart';

class Clusters extends StatefulWidget implements PocPage {
  const Clusters({super.key});

  @override
  final Widget leading = const Icon(Icons.bubble_chart_outlined);
  @override
  final String title = 'Clusters';
  @override
  final String subtitle = 'Display clustered points on the map';

  @override
  State<StatefulWidget> createState() => _ClusterMap();
}

class _ClusterMap extends SimpleMapState {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _addLayerAndSource() async {
    mapboxMap?.style.styleSourceExists("earthquakes").then((value) async {
      if (!value) {
        var source = await rootBundle.loadString(
          'assets/cluster/cluster_source.json',
        );
        mapboxMap?.style.addStyleSource("earthquakes", source);
      }
    });

    mapboxMap?.style.styleLayerExists("clusters").then((value) async {
      if (!value) {
        // Use step expressions (https://docs.mapbox.com/mapbox-gl-js/style-spec/#expressions-step)
        // with three steps to implement three types of circles:
        //   * Blue, 20px circles when point count is less than 100
        //   * Yellow, 30px circles when point count is between 100 and 750
        //   * Pink, 40px circles when point count is greater than or equal to 750
        var layer = await rootBundle.loadString(
          'assets/cluster/cluster_layer.json',
        );
        mapboxMap?.style.addStyleLayer(layer, null);

        var tapInteraction = (String layerName) => TapInteraction(
          FeaturesetDescriptor(layerId: layerName),
          (feature, context) async {
            var featureId = feature.id.toString();

            // Handle tap when a feature from "polygons" is tapped.
            print("Tapped feature: $featureId");
            print("Tapped feature properties: ${feature.properties}");
            print("Tapped feature properties: ${feature.state}");

            print("Tapped feature name: ${feature.properties['name']}");
            print("Tapped feature coordinates: ${feature.geometry.toString()}");
          },
        );
        mapboxMap?.addInteraction(tapInteraction("clusters"));

        var clusterCountLayer = await rootBundle.loadString(
          'assets/cluster/cluster_count_layer.json',
        );
        mapboxMap?.style.addStyleLayer(clusterCountLayer, null);
        mapboxMap?.addInteraction(tapInteraction("cluster-count"));

        var unclusteredLayer = await rootBundle.loadString(
          'assets/cluster/unclustered_point_layer.json',
        );
        mapboxMap?.style.addStyleLayer(unclusteredLayer, null);
        mapboxMap?.addInteraction(tapInteraction("unclustered-point"));
      }
    });
  }

  var feature = {
    "id": 1249,
    "properties": {
      "point_count_abbreviated": "10",
      "cluster_id": 1249,
      "cluster": true,
      "point_count": 10,
    },
    "geometry": {
      "type": "Point",
      "coordinates": [-29.794921875, 59.220934076150456],
    },
    "type": "Feature",
  };

  @override
  onStyleLoaded(StyleLoadedEventData styleEvent) async {
    super.onStyleLoaded(styleEvent);
    _addLayerAndSource();

    // TODO: implement clustering logic
  }
  @override
  CameraViewportState get camera => CameraViewportState(
   center: Point(
            coordinates: Position(
          -103.94925008414447,
          10.867890040082585,
        )),
        zoom: 1,
        pitch: 0
  );
  
  @override
  onMapCreated() async {
    super.onMapCreated();
    // TODO: implement clustering logic
  }
}
