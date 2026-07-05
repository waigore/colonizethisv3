import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/flame/render/gp_ownership_tint_layer.dart';

RegionMapViewData _minimalRegion({
  required List<CellViewData> cells,
  Map<String, (int, int, int)>? factionColors,
  Set<String>? greatPowerFactionIds,
}) {
  return RegionMapViewData(
    regionId: 'testRegion',
    width: cells.isEmpty
        ? 1
        : cells.map((c) => c.x + 1).reduce((a, b) => a > b ? a : b),
    height: cells.isEmpty
        ? 1
        : cells.map((c) => c.y + 1).reduce((a, b) => a > b ? a : b),
    cellSize: 24,
    cells: cells,
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: factionColors ?? const {},
    greatPowerFactionIds: greatPowerFactionIds ?? const {},
    terrainColors: const {TerrainType.plains: (100, 150, 80)},
  );
}

Future<(int r, int g, int b, int a)> _pixelStraightRgba(
  ui.Image image,
  int x,
  int y,
) async {
  final bd = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  expect(bd, isNotNull);
  final i = (y * image.width + x) * 4;
  return (
    bd!.getUint8(i),
    bd.getUint8(i + 1),
    bd.getUint8(i + 2),
    bd.getUint8(i + 3),
  );
}

void main() {
  suppressLogsForTests();

  group('paintGreatPowerOwnershipTintLayer', () {
    test('applies strong red tint over white on GP-owned land cell', () async {
      const cell = 24;
      final region = _minimalRegion(
        cells: [
          const CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p0',
            isSea: false,
            ownerFactionId: 'gp1',
            terrainType: TerrainType.plains,
          ),
          const CellViewData(
            x: 1,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            ownerFactionId: null,
            terrainType: TerrainType.plains,
          ),
        ],
        factionColors: const {'gp1': (255, 0, 0)},
        greatPowerFactionIds: const {'gp1'},
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, cell * 2.0, cell.toDouble()),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      paintGreatPowerOwnershipTintLayer(
        canvas: canvas,
        region: region,
        cellSize: cell.toDouble(),
        honorUnrevealedTiles: false,
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(cell * 2, cell);
      addTearDown(image.dispose);

      final tinted = await _pixelStraightRgba(image, cell ~/ 2, cell ~/ 2);
      final untouched = await _pixelStraightRgba(
        image,
        cell + cell ~/ 2,
        cell ~/ 2,
      );

      expect(tinted.$4, 255);
      expect(untouched.$1, greaterThan(250));
      expect(untouched.$2, greaterThan(250));
      expect(untouched.$3, greaterThan(250));

      expect(tinted.$1, greaterThan(240));
      // srcOver red (255,0,0) at kGpOwnershipTintAlpha over white → G/B ≈ 255*(1-alpha).
      expect(tinted.$2, inInclusiveRange(110, 140));
      expect(tinted.$3, inInclusiveRange(110, 140));
    });

    test('skips sea cells and non-GP owners', () async {
      const cell = 16;
      final region = _minimalRegion(
        cells: [
          const CellViewData(
            x: 0,
            y: 0,
            regionCellId: 's0',
            isSea: true,
            ownerFactionId: 'gp1',
          ),
          const CellViewData(
            x: 1,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            ownerFactionId: 'minor1',
            terrainType: TerrainType.plains,
          ),
        ],
        factionColors: const {'gp1': (255, 0, 0), 'minor1': (0, 0, 255)},
        greatPowerFactionIds: const {'gp1'},
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, cell * 2.0, cell.toDouble()),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      paintGreatPowerOwnershipTintLayer(
        canvas: canvas,
        region: region,
        cellSize: cell.toDouble(),
        honorUnrevealedTiles: false,
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(cell * 2, cell);
      addTearDown(image.dispose);

      final seaPx = await _pixelStraightRgba(image, cell ~/ 2, cell ~/ 2);
      final minorPx = await _pixelStraightRgba(
        image,
        cell + cell ~/ 2,
        cell ~/ 2,
      );
      expect(seaPx.$1, greaterThan(250));
      expect(minorPx.$1, greaterThan(250));
    });

    test('honors unrevealed when honorUnrevealedTiles is true', () async {
      const cell = 16;
      final region = _minimalRegion(
        cells: [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p0',
            isSea: false,
            ownerFactionId: 'gp1',
            terrainType: TerrainType.plains,
            visibility: TileVisibility.unrevealed,
          ),
        ],
        factionColors: const {'gp1': (255, 0, 0)},
        greatPowerFactionIds: const {'gp1'},
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, cell.toDouble(), cell.toDouble()),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      paintGreatPowerOwnershipTintLayer(
        canvas: canvas,
        region: region,
        cellSize: cell.toDouble(),
        honorUnrevealedTiles: true,
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(cell, cell);
      addTearDown(image.dispose);

      final px = await _pixelStraightRgba(image, cell ~/ 2, cell ~/ 2);
      expect(px.$1, greaterThan(250));
      expect(px.$2, greaterThan(250));
    });
  });

  test('kGpOwnershipTintAlpha matches map spec (0.5)', () {
    expect(kGpOwnershipTintAlpha, 0.5);
  });
}
