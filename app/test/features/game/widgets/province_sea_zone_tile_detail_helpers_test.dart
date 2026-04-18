import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

void main() {
  suppressLogsForTests();
  group('tryParseProvinceOverlayTileCoords', () {
    test('returns null when region id does not match', () {
      expect(
        tryParseProvinceOverlayTileCoords(
          regionId: 'oldWorld',
          regionWidth: 20,
          regionHeight: 15,
          selectedTileKey: 'newWorld|prov|3|4',
        ),
        isNull,
      );
    });

    test('returns null when coordinates are out of range', () {
      expect(
        tryParseProvinceOverlayTileCoords(
          regionId: 'oldWorld',
          regionWidth: 5,
          regionHeight: 5,
          selectedTileKey: 'oldWorld|prov|10|0',
        ),
        isNull,
      );
    });

    test('parses valid tile key', () {
      final c = tryParseProvinceOverlayTileCoords(
        regionId: 'oldWorld',
        regionWidth: 20,
        regionHeight: 15,
        selectedTileKey: 'oldWorld|prov|3|4',
      );
      expect(c, isNotNull);
      expect(c!.x, 3);
      expect(c.y, 4);
    });

    test('parses x|y from last two segments when local id contains a pipe', () {
      final c = tryParseProvinceOverlayTileCoords(
        regionId: 'newWorld',
        regionWidth: 20,
        regionHeight: 15,
        selectedTileKey: 'newWorld|newWorld|provA|3|4',
      );
      expect(c, isNotNull);
      expect(c!.x, 3);
      expect(c.y, 4);
    });
  });

  group('tileDetailProspectedDisplayLabel', () {
    test('not prospectable yields em dash', () {
      expect(
        tileDetailProspectedDisplayLabel(
          terrainProspectable: false,
          playerHasProspected: true,
        ),
        '—',
      );
    });

    test('prospectable and prospected yields yes', () {
      expect(
        tileDetailProspectedDisplayLabel(
          terrainProspectable: true,
          playerHasProspected: true,
        ),
        'yes',
      );
    });

    test('prospectable and not prospected yields no', () {
      expect(
        tileDetailProspectedDisplayLabel(
          terrainProspectable: true,
          playerHasProspected: false,
        ),
        'no',
      );
    });
  });
}
