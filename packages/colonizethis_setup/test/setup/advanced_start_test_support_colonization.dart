// Colonization / development / prospecting / world-knowledge game fixtures.
// SPEC/game/advanced-starts.md (Refs #4086 Slice D).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'advanced_start_test_support_gp.dart';
import 'advanced_start_test_support_maps.dart';
import 'advanced_start_test_support_world.dart';

/// Development fixture: GP + minor OW capitals with towns and resources.
Game advancedStartDevelopmentFixture({
  Map<String, String>? resourceByTileKey,
  Map<String, Set<String>>? playerProspectedTiles,
  Map<String, List<String>>? owTiles,
}) {
  return advancedStartWorldGame(
    oldWorldProvinces: [
      Province(
        id: 'oldWorld|p1',
        regionId: kRegionOldWorld,
        ownerId: 'gp1',
        townTileKey: 'oldWorld|p1|1|1',
      ),
      Province(
        id: 'oldWorld|m1',
        regionId: kRegionOldWorld,
        ownerId: 'minor1',
        townTileKey: 'oldWorld|m1|0|0',
      ),
    ],
    newWorldProvinces: const [],
    owTiles:
        owTiles ??
        {
          'oldWorld|p1': [
            'oldWorld|p1|0|0',
            'oldWorld|p1|1|0',
            'oldWorld|p1|1|1',
            'oldWorld|p1|2|0',
          ],
          'oldWorld|m1': [
            'oldWorld|m1|0|0',
            'oldWorld|m1|1|0',
            'oldWorld|m1|2|0',
          ],
        },
    nwTiles: null,
    resourceByTileKey:
        resourceByTileKey ??
        {
          'oldWorld|p1|0|0': 'grain',
          'oldWorld|p1|1|0': 'timber',
          'oldWorld|p1|2|0': 'wool',
          'oldWorld|m1|1|0': 'grain',
          'oldWorld|m1|2|0': 'meat',
        },
    playerProspectedTiles: playerProspectedTiles,
    player: const Player(
      id: 'gp1',
      displayName: 'England',
      isHuman: true,
      capitalProvinceId: 'oldWorld|p1',
      capitalTile: CapitalTile(
        regionId: kRegionOldWorld,
        provinceId: 'p1',
        x: 1,
        y: 1,
      ),
    ),
    minorNations: const [
      MinorNation(
        id: 'minor1',
        displayName: 'Minor 1',
        capitalProvinceId: 'oldWorld|m1',
        capitalTile: CapitalTile(
          regionId: kRegionOldWorld,
          provinceId: 'm1',
          x: 0,
          y: 0,
        ),
      ),
    ],
    turnNumber: 50,
  );
}

Game advancedStartColonizationFixture({List<Province> nwProvinces = const []}) {
  return TestFixtures.minimalGame(
    id: 'g1',
    turnNumber: 100,
    oldWorld: const RegionData(provinces: []),
    newWorld: RegionData(provinces: nwProvinces),
    tileKeysByRegionAndProvince: {
      kRegionNewWorld: {
        for (final p in nwProvinces)
          ProvinceId.prefixedFrom(p.regionId, p.id): [
            '${ProvinceId.prefixedFrom(p.regionId, p.id)}|0|0',
          ],
      },
    },
    players: const [advancedStartDefaultPlayer],
    tribes: const [
      Tribe(id: 'tribe1', displayName: 'Tribe 1'),
      Tribe(id: 'tribe2', displayName: 'Tribe 2'),
    ],
  );
}

Game advancedStartProspectingFixture({
  required List<Province> owProvinces,
  required List<Province> nwProvinces,
  required Map<String, String> resourceByTileKey,
  required Map<String, List<String>> owTiles,
  required Map<String, List<String>> nwTiles,
}) {
  return advancedStartWorldGame(
    oldWorldProvinces: owProvinces,
    newWorldProvinces: nwProvinces,
    owTiles: owTiles,
    nwTiles: nwTiles,
    resourceByTileKey: resourceByTileKey,
    player: advancedStartDefaultPlayer,
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    turnNumber: 50,
  );
}

Game advancedStartWorldKnowledgeFixture() {
  return advancedStartWorldGame(
    oldWorldProvinces: const [],
    newWorldProvinces: [
      Province(id: 'newWorld|p1', regionId: kRegionNewWorld, ownerId: 'tribe1'),
      Province(id: 'newWorld|p2', regionId: kRegionNewWorld, ownerId: 'tribe1'),
      Province(id: 'newWorld|p3', regionId: kRegionNewWorld, ownerId: 'tribe2'),
    ],
    owTiles: null,
    nwTiles: advancedStartWorldKnowledgeNwTiles,
    resourceByTileKey: {
      'newWorld|p1|0|0': 'iron',
      'newWorld|p1|1|0': 'grain',
      'newWorld|p2|0|0': 'gold',
      'newWorld|p3|0|0': 'copper',
    },
    playerVisibilityByTile: {
      'gp1': {
        'newWorld|p1|0|0': VisibilityLevel.unknown.name,
        'newWorld|p1|1|0': VisibilityLevel.unknown.name,
        'newWorld|p2|0|0': VisibilityLevel.unknown.name,
        'newWorld|p3|0|0': VisibilityLevel.unknown.name,
        'newWorld|s1|0|0': VisibilityLevel.unknown.name,
        'newWorld|s2|0|0': VisibilityLevel.unknown.name,
        'newWorld|s3|0|0': VisibilityLevel.unknown.name,
      },
    },
    player: advancedStartDefaultPlayer,
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    tribes: const [
      Tribe(id: 'tribe1', displayName: 'Tribe 1'),
      Tribe(id: 'tribe2', displayName: 'Tribe 2'),
    ],
    turnNumber: 50,
  );
}
