import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';

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

  const variantKeys = [
    'tile_plains_grain',
    'tile_plains_meat',
    'tile_plains_horses',
    'tile_plains_sugar_cane',
    'tile_plains_tobacco',
    'tile_plains_cotton',
    'tile_plains_spices',
  ];

  group('L1 plains resource variants (Refs #1600)', () {
    test(
      'transparent overlay pixels show interior plains when base is drawn first',
      () async {
        final cache = TerrainTilesetCache();
        await cache.load();
        expect(cache.isLoaded, isTrue);

        final interior = cache.getSeaPlainsTileset();
        expect(interior, isNotNull);
        expect(interior!.upperBaseTileId, isNotNull);
        final baseTile = interior.findTileById(interior.upperBaseTileId!);
        expect(baseTile, isNotNull);

        for (final key in variantKeys) {
          final overlay = cache.getStandaloneTileByKey(key);
          expect(overlay, isNotNull, reason: 'missing $key');

          Future<ui.Image> renderComposed({
            required bool drawInteriorPlainsBase,
          }) async {
            const size = 64;
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);
            canvas.drawRect(
              const Rect.fromLTWH(0, 0, 64, 64),
              Paint()..color = const Color(0xFF000000),
            );
            if (drawInteriorPlainsBase) {
              canvas.drawImageRect(
                interior.image,
                baseTile!.boundingBox,
                const Rect.fromLTWH(0, 0, 64, 64),
                Paint(),
              );
            }
            canvas.drawImageRect(
              overlay!.image,
              Rect.fromLTWH(
                0,
                0,
                overlay.image.width.toDouble(),
                overlay.image.height.toDouble(),
              ),
              const Rect.fromLTWH(0, 0, 64, 64),
              Paint(),
            );

            final picture = recorder.endRecording();
            final image = await picture.toImage(size, size);
            addTearDown(image.dispose);
            return image;
          }

          final variantOnly = await renderComposed(
            drawInteriorPlainsBase: false,
          );
          final withBase = await renderComposed(drawInteriorPlainsBase: true);

          final blackCorner = await _pixelStraightRgba(variantOnly, 0, 0);
          expect(
            blackCorner.$1 + blackCorner.$2 + blackCorner.$3,
            lessThan(12),
            reason:
                '$key: (0,0) should stay black when overlay is transparent '
                'and no base is drawn',
          );

          final composed = await _pixelStraightRgba(withBase, 0, 0);
          expect(
            composed.$1 + composed.$2 + composed.$3,
            greaterThan(40),
            reason:
                '$key: (0,0) should pick up interior plains when base is drawn '
                'under transparent overlay pixels',
          );
        }
      },
    );
  });
}
