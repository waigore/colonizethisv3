import 'dart:convert';
import 'dart:typed_data';

import 'package:colonizethis_app/features/game/flame/minimap/minimap.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

const kRegionMinimapIconAssetPath =
    'assets/icons/32/ui_icon_region_minimap.png';

ByteData regionMinimapOneByOnePngByteData() {
  final bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
  return ByteData.sublistView(Uint8List.fromList(bytes));
}

final class RegionMinimapTestAssetBundle extends CachingAssetBundle {
  RegionMinimapTestAssetBundle(this._parent);

  final AssetBundle _parent;

  @override
  Future<ByteData> load(String key) async {
    if (key == kRegionMinimapIconAssetPath) {
      return regionMinimapOneByOnePngByteData();
    }
    return _parent.load(key);
  }
}

Widget regionMinimapTestShell(Widget child) {
  return buildAppShell(
    shellWrapper: (app) => DefaultAssetBundle(
      bundle: RegionMinimapTestAssetBundle(rootBundle),
      child: app,
    ),
    child: Scaffold(body: Center(child: child)),
  );
}

RegionMapViewData regionMinimapTestRegion({
  required String regionId,
  required int w,
  required int h,
}) {
  const cellSize = 24;
  final cells = <CellViewData>[
    for (var y = 0; y < h; y++)
      for (var x = 0; x < w; x++)
        CellViewData(
          x: x,
          y: y,
          regionCellId: 'c$x$y',
          isSea: false,
          terrainType: TerrainType.plains,
          visibility: TileVisibility.visible,
        ),
  ];
  return RegionMapViewData(
    regionId: regionId,
    width: w,
    height: h,
    cellSize: cellSize,
    cells: cells,
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {},
    terrainColors: const {TerrainType.plains: (100, 150, 80)},
  );
}

const double kRegionMinimapNarrowBoxAspect =
    GameRegionMinimap.narrowMaxWidth / GameRegionMinimap.narrowMaxHeight;
