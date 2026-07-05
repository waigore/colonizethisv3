import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_app/config/map_terrain_config.dart';
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';

void main() {
  group('TransportOverlayTilesetCache', () {
    test('loads road and rail families with masks 0..15', () async {
      final cache = TransportOverlayTilesetCache();
      await cache.load();

      for (final family in TransportTileFamily.values) {
        final tileset = cache.getTileset(family);
        expect(tileset, isNotNull, reason: 'Missing tileset for $family');
        final masks = tileset!.maskRects.keys.toSet();
        expect(masks.length, 16, reason: 'Expected 16 masks for $family');
        for (var i = 0; i < 16; i++) {
          expect(masks.contains(i), isTrue, reason: '$family missing mask $i');
        }
      }
    });

    test(
      'loaded mask rects match configured tile size and atlas bounds',
      () async {
        final cache = TransportOverlayTilesetCache();
        await cache.load();
        final config = MapTerrainConfig.instance;

        for (final family in TransportTileFamily.values) {
          final key = family.name;
          final familyConfig = config.transportTilesets[key];
          expect(familyConfig, isNotNull, reason: 'Missing config for $key');
          final tileset = cache.getTileset(family);
          expect(tileset, isNotNull, reason: 'Missing loaded tileset for $key');

          final tilePx = familyConfig!.tilePx.toDouble();
          for (final entry in tileset!.maskRects.entries) {
            final mask = entry.key;
            final rect = entry.value;
            expect(
              rect.width,
              tilePx,
              reason: '$key mask $mask width mismatch',
            );
            expect(
              rect.height,
              tilePx,
              reason: '$key mask $mask height mismatch',
            );
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.top, greaterThanOrEqualTo(0));
            expect(
              rect.right,
              lessThanOrEqualTo(tileset.image.width.toDouble()),
              reason: '$key mask $mask exceeds atlas width',
            );
            expect(
              rect.bottom,
              lessThanOrEqualTo(tileset.image.height.toDouble()),
              reason: '$key mask $mask exceeds atlas height',
            );
          }
        }
      },
    );

    test('mask rects are grid aligned and unique per family', () async {
      final cache = TransportOverlayTilesetCache();
      await cache.load();
      final config = MapTerrainConfig.instance;

      for (final family in TransportTileFamily.values) {
        final key = family.name;
        final familyConfig = config.transportTilesets[key];
        expect(familyConfig, isNotNull, reason: 'Missing config for $key');
        final tileset = cache.getTileset(family);
        expect(tileset, isNotNull, reason: 'Missing loaded tileset for $key');
        final tilePx = familyConfig!.tilePx.toDouble();
        final seenRects = <String>{};

        for (final entry in tileset!.maskRects.entries) {
          final mask = entry.key;
          final rect = entry.value;
          expect(
            rect.left % tilePx,
            0,
            reason: '$key mask $mask left is not aligned to tile grid',
          );
          expect(
            rect.top % tilePx,
            0,
            reason: '$key mask $mask top is not aligned to tile grid',
          );
          final rectKey =
              '${rect.left},${rect.top},${rect.width},${rect.height}';
          expect(
            seenRects.add(rectKey),
            isTrue,
            reason: '$key mask $mask reuses an existing source rect',
          );
        }
      }
    });
  });
}
