import 'package:colonizethis_map/src/region_constants.dart';
import 'package:colonizethis_map/src/region_map_view_inputs.dart';
import 'package:colonizethis_map/src/tile_map_capital_markers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _gameWithRegions({
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: oldWorldProvinces, units: const []),
      newWorld: RegionData(provinces: newWorldProvinces, units: const []),
    ),
    players: const [
      Player(
        id: 'gp1',
        displayName: 'Spain',
        isHuman: true,
        capitalTile: CapitalTile(
          regionId: kRegionOldWorld,
          provinceId: 'oldWorld|p1',
          x: 1,
          y: 2,
        ),
      ),
    ],
    minorNations: const [],
    tribes: const [
      Tribe(
        id: 'tribe1',
        displayName: 'Aztec',
        capitalTile: CapitalTile(
          regionId: kRegionNewWorld,
          provinceId: 'newWorld|p1',
          x: 3,
          y: 4,
        ),
      ),
    ],
  );
}

void main() {
  group('isOldWorldRegionId', () {
    test('matches old world constant only', () {
      expect(isOldWorldRegionId(kRegionOldWorld), isTrue);
      expect(isOldWorldRegionId(kRegionNewWorld), isFalse);
    });
  });

  group('provincesForGameRegion', () {
    test('returns old or new world provinces', () {
      final game = _gameWithRegions(
        oldWorldProvinces: [Province(id: 'ow|p1', regionId: kRegionOldWorld)],
        newWorldProvinces: [Province(id: 'nw|p1', regionId: kRegionNewWorld)],
      );
      expect(
        provincesForGameRegion(game, kRegionOldWorld).single.id,
        'ow|p1',
      );
      expect(
        provincesForGameRegion(game, kRegionNewWorld).single.id,
        'nw|p1',
      );
    });
  });

  group('capitalMarkerScopeForRegion', () {
    test('selects old or new world faction scope', () {
      expect(
        capitalMarkerScopeForRegion(kRegionOldWorld),
        TileMapCapitalMarkerScope.oldWorldFactions,
      );
      expect(
        capitalMarkerScopeForRegion(kRegionNewWorld),
        TileMapCapitalMarkerScope.newWorldFactions,
      );
    });
  });

  group('regionMapRenderInputs', () {
    test('bundles ownership, capitals, and colours per region', () {
      final game = _gameWithRegions(
        oldWorldProvinces: [
          Province(
            id: 'ow|p1',
            regionId: kRegionOldWorld,
            ownerId: 'gp1',
          ),
        ],
        newWorldProvinces: [
          Province(
            id: 'nw|p1',
            regionId: kRegionNewWorld,
            ownerId: 'tribe1',
          ),
        ],
      );

      final ow = regionMapRenderInputs(game: game, regionId: kRegionOldWorld);
      expect(ow.ownerByProvinceId, equals({'ow|p1': 'gp1'}));
      expect(ow.capitalTiles, hasLength(1));
      expect(ow.capitalTiles.single.factionId, 'gp1');
      expect(ow.factionColors.containsKey('gp1'), isTrue);
      expect(ow.factionColors.containsKey('tribe1'), isFalse);

      final nw = regionMapRenderInputs(game: game, regionId: kRegionNewWorld);
      expect(nw.ownerByProvinceId, equals({'nw|p1': 'tribe1'}));
      expect(nw.capitalTiles.single.factionId, 'tribe1');
      expect(nw.factionColors.containsKey('tribe1'), isTrue);
      expect(nw.factionColors.containsKey('gp1'), isFalse);
    });
  });
}
