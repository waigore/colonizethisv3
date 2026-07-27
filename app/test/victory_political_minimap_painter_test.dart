// Widget tests for Victory political minimap painter. SPEC/ui/victory-panel.md.

import 'dart:ui' as ui;

import 'package:colonizethis_app/features/game/screens/victory/victory_political_minimap_painter.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';
import 'package:flutter/material.dart';

void main() {
  test('VictoryPoliticalMinimapPainter paints land and sea without throwing', () async {
    final region = RegionMapViewData(
      regionId: 'oldWorld',
      width: 2,
      height: 2,
      cellSize: 8,
      cells: [
        CellViewData(x: 0, y: 0, regionCellId: 'p1', isSea: false, ownerFactionId: 'gp1'),
        CellViewData(x: 1, y: 0, regionCellId: 'p1', isSea: false, ownerFactionId: 'gp1'),
        CellViewData(x: 0, y: 1, regionCellId: 'sea1', isSea: true),
        CellViewData(x: 1, y: 1, regionCellId: 'p2', isSea: false, ownerFactionId: 'minor1'),
      ],
      capitalMarkers: const [],
      portMarkers: const [],
      factionColors: {
        'gp1': (180, 80, 80),
        'minor1': (128, 128, 128),
      },
      greatPowerFactionIds: {'gp1'},
      terrainColors: const {},
      unitMarkers: const [],
      civilianTileMarkers: const [],
      fleetTileMarkers: const [],
      warpMarkers: const [],
      townMarkers: const [],
      provinceUnitPresenceByProvinceId: const {},
      provincePoliticalOwnerByPrefixedProvinceId: const {},
      seaZoneDisplayNameByPrefixedId: const {},
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    VictoryPoliticalMinimapPainter(
      region: region,
      highlightedProvinceLocalId: 'p2',
    ).paint(canvas, const Size(40, 40));
    expect(recorder.endRecording(), isNotNull);
  });
}
