import 'package:colonizethis_map/src/tile_map_capital_markers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _gameWithCapitals() {
  return Game(
    id: 'test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(provinces: [], units: []),
      newWorld: const RegionData(provinces: [], units: []),
    ),
    players: const [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 1,
          y: 2,
        ),
      ),
    ],
    minorNations: const [
      MinorNation(
        id: 'minor1',
        displayName: 'Minor',
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p2',
          x: 3,
          y: 4,
        ),
      ),
    ],
    tribes: const [
      Tribe(
        id: 'tribe1',
        displayName: 'Tribe',
        capitalTile: CapitalTile(
          regionId: 'newWorld',
          provinceId: 'newWorld|p1',
          x: 5,
          y: 6,
        ),
      ),
    ],
  );
}

void main() {
  group('collectCapitalMarkersForRegion', () {
    test('oldWorldFactions includes players and minors only', () {
      final markers = collectCapitalMarkersForRegion(
        game: _gameWithCapitals(),
        regionId: 'oldWorld',
        scope: TileMapCapitalMarkerScope.oldWorldFactions,
      );
      expect(markers.map((m) => m.factionId).toList(), ['gp1', 'minor1']);
    });

    test('newWorldFactions includes tribes only', () {
      final markers = collectCapitalMarkersForRegion(
        game: _gameWithCapitals(),
        regionId: 'newWorld',
        scope: TileMapCapitalMarkerScope.newWorldFactions,
      );
      expect(markers.map((m) => m.factionId).toList(), ['tribe1']);
      expect(markers.single.x, 5);
      expect(markers.single.y, 6);
    });

    test('allFactions includes every faction with capital in region', () {
      final markers = collectCapitalMarkersForRegion(
        game: _gameWithCapitals(),
        regionId: 'oldWorld',
        scope: TileMapCapitalMarkerScope.allFactions,
      );
      expect(markers.map((m) => m.factionId).toList(), ['gp1', 'minor1']);
    });

    test('skips factions whose capital is in another region', () {
      final markers = collectCapitalMarkersForRegion(
        game: _gameWithCapitals(),
        regionId: 'newWorld',
        scope: TileMapCapitalMarkerScope.oldWorldFactions,
      );
      expect(markers, isEmpty);
    });
  });
}
