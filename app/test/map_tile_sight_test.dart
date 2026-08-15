// Pins MAP10001 / MAP20001 sight phrases and tile-key lookup (Refs #4406).
import 'package:colonizethis_app/features/game/flame/controls/map_tile_sight.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('mapTileSightPhrase maps three visibilities without enum text', () {
    expect(mapTileSightPhrase(l10n, TileVisibility.visible), 'Fully visible');
    expect(
      mapTileSightPhrase(l10n, TileVisibility.fogged),
      'Fogged — terrain only',
    );
    expect(
      mapTileSightPhrase(l10n, TileVisibility.unrevealed),
      'Unknown — no intel yet',
    );
    expect(mapTileSightPhrase(l10n, TileVisibility.visible), isNot('visible'));
    expect(mapTileSightPhrase(l10n, TileVisibility.fogged), isNot('fogged'));
    expect(
      mapTileSightPhrase(l10n, TileVisibility.unrevealed),
      isNot('unrevealed'),
    );
  });

  test(
    'cellViewDataForMapTileKey rejects malformed and out-of-region keys',
    () {
      const region = RegionMapViewData(
        regionId: 'oldWorld',
        width: 1,
        height: 1,
        cellSize: 16,
        cells: [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            visibility: TileVisibility.visible,
          ),
        ],
        capitalMarkers: [],
        portMarkers: [],
        factionColors: {},
        greatPowerFactionIds: {},
        terrainColors: {},
      );
      expect(
        cellViewDataForMapTileKey(region, 'oldWorld|p1|0|0')?.regionCellId,
        'p1',
      );
      expect(cellViewDataForMapTileKey(region, 'oldWorld|p1|0'), isNull);
      expect(cellViewDataForMapTileKey(region, 'newWorld|p1|0|0'), isNull);
      expect(cellViewDataForMapTileKey(region, 'oldWorld|p1|9|9'), isNull);
    },
  );
}
