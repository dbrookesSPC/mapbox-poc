import 'package:flutter/material.dart';
import 'package:maps_poc/page.dart';
import 'package:maps_poc/pages/annotations/annotations.dart';
import 'package:maps_poc/pages/polygons/polygons.dart';
import 'package:maps_poc/pages/clusters/clusters.dart';
import 'package:maps_poc/pages/offline/offline_mode.dart';
import 'package:maps_poc/pages/markers/many_markers.dart';

// Annotations
// Polygons
// Clusters
// OfflineMode
// ManyMarkers

final List<PocPage> _allPages = <PocPage>[
  Annotations(),
  Polygons(),
  Clusters(),
  OfflineMode(),
  ManyMarkers(),
];

class MyHomePage extends StatelessWidget {
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  void _pushPage(BuildContext context, PocPage page) async {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
              appBar: AppBar(title: Text(page.title)),
              body: page,
            )));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Pages"),
      ),
      body: ListView.separated(
        itemCount: _allPages.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, int index) {
          final example = _allPages[index];
          return ListTile(
            leading: example.leading,
            title: Text(example.title),
            subtitle: (example.subtitle?.isNotEmpty == true)
                ? Text(
                    example.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            onTap: () => _pushPage(context, _allPages[index]),
          );
        },
      ),
    );
  }
}

