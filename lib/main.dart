import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import 'package:path_provider/path_provider.dart';

import 'coords_ext.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoading = false;
  bool offlineMode = false;
  String offlineUrlTemp;
  bool useMemoryImage = false;
  MapController mapController = MapController();

  Future<void> _incrementCounter() async {
    if (offlineMode) {
      setState(() {
        offlineMode = false;
      });
    }
    List<Coords> sourceCoords = CoordsUtil().getTileCoordsByBounds(
        mapController.bounds, mapController.zoom.round());

    Dio dio = new Dio();
    Directory directory = await getApplicationDocumentsDirectory();
    setState(() {
      isLoading = true;
    });
    for (final tile in sourceCoords) {
      final savePath =
          join(directory.path, '${tile.z}/${tile.x}/${tile.y}.jpg');
      final url =
          'https://api.maptiler.com/maps/hybrid/256/${tile.z}/${tile.x}/${tile.y}@2x.jpg?key=S8sd6NmKlFwwJSxgnvEd';
      await dio.download(url, savePath, onReceiveProgress: (received, total) {
        print('Task $url, progress: ${(received / total * 100)}%');
      });
    }

    setState(() {
      isLoading = false;
      offlineMode = true;
    });
  }

  @override
  void initState() {
    super.initState();
    getApplicationDocumentsDirectory().then((value) {
      offlineUrlTemp = join(value.path, '{z}/{x}/{y}.jpg');
    });
  }

  @override
  Widget build(BuildContext context) {
    final urlTemp = offlineMode
        ? offlineUrlTemp
        : 'https://api.maptiler.com/maps/hybrid/256/{z}/{x}/{y}@2x.jpg?key=S8sd6NmKlFwwJSxgnvEd';
    final tileProvider = offlineMode
        ? FileTileProvider(useMemoryImage)
        : NonCachingNetworkTileProvider();
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(offlineMode ? 'offline' : 'online'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
                center: LatLng(49.2484, -100.6183),
                zoom: 11,
                maxZoom: 12,
                minZoom: 11),
            layers: [
              TileLayerOptions(
                  key: UniqueKey(),
                  urlTemplate: urlTemp,
                  tileProvider: tileProvider)
            ],
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
          Align(
            alignment: Alignment.bottomLeft,
            child: FlatButton(
              color: Colors.green,
              child: Text('useMemoryImage'),
              onPressed: () {
                setState(() {
                  useMemoryImage = true;
                  print('change');
                });
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class FileTileProvider extends TileProvider {
  bool useMemoryImage;

  FileTileProvider(this.useMemoryImage);

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    final url = getTileUrl(coords, options);
    final file = File(url);
    if (useMemoryImage) {
      Uint8List bytes = file.readAsBytesSync();
      return MemoryImage(bytes);
    }
    return FileImage(File(getTileUrl(coords, options)));
  }
}
