import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';
import 'dart:math' as Math;

class CoordsUtil {
  static const TILE_SIZE = 256;

  Crs crs = Epsg3857();

  CustomPoint mapSize = CustomPoint(TILE_SIZE, TILE_SIZE);

  List<Coords> generateTileCoordsFromCurrentState(
      CustomPoint size, LatLng center, double toZoom) {
    var scale = _getZoomScale(toZoom, toZoom);
    var pixelCenter = crs.latLngToPoint(center, toZoom).floor();
    var halfSize = size / (scale * 2);

    Bounds bounds = Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
    var tileRange = Bounds(bounds.min.unscaleBy(mapSize).floor(),
        bounds.max.unscaleBy(mapSize).ceil() - const CustomPoint(1, 1));

    List<Coords> coordsList = [];
    for (var j = tileRange.min.y; j <= tileRange.max.y; j++) {
      for (var i = tileRange.min.x; i <= tileRange.max.x; i++) {
        var coords = Coords(i, j);
        coords.z = toZoom.round();
        coordsList.add(coords);
      }
    }
    return coordsList;
  }

  List<Coords> getTileCoordsByBounds(LatLngBounds bounds, int zoom) {
    final northWest = bounds.northWest;
    final southEast = bounds.southEast;
    final northWestTile = toTileCoords(northWest, zoom);
    final southEastTile = toTileCoords(southEast, zoom);
    List<Coords> coords = [];
    for (int i = northWestTile.x; i <= southEastTile.x; i++) {
      for (int j = northWestTile.y; j <= southEastTile.y; j++) {
        coords.add(Coords(i, j)..z = zoom);
      }
    }
    return coords;
  }

  Coords toTileCoords(LatLng latLng, int zoom) {
    final scale = 1 << zoom;
    final worldCoordinate = project(latLng);
    final x = ((worldCoordinate.x * scale) / TILE_SIZE).floor();
    final y = ((worldCoordinate.y * scale) / TILE_SIZE).floor();
    return Coords(x, y)..z = zoom;
  }

  CustomPoint toPixelCoordinate(LatLng latLng, int zoom) {
    final scale = 1 << zoom;
    final worldCoordinate = project(latLng);
    final x = (worldCoordinate.x * scale).floor();
    final y = (worldCoordinate.y * scale).floor();
    return CustomPoint(x, y);
  }

  WorldCoordinate project(LatLng latLng) {
    var siny = Math.sin((latLng.latitude * Math.pi) / 180);
    // Truncating to 0.9999 effectively limits latitude to 89.189. This is
    // about a third of a tile past the edge of the world tile.
    siny = Math.min(Math.max(siny, -0.9999), 0.9999);
    return WorldCoordinate(TILE_SIZE * (0.5 + latLng.longitude / 360),
        TILE_SIZE * (0.5 - Math.log((1 + siny) / (1 - siny)) / (4 * Math.pi)));
  }

  double _getZoomScale(double toZoom, double fromZoom) {
    return crs.scale(toZoom) / crs.scale(fromZoom);
  }
}

class WorldCoordinate {
  final double x;
  final double y;

  WorldCoordinate(this.x, this.y);
}
