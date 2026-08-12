import 'package:colonizethis_world/src/world/naval_coastal_visibility.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'world_test_support/world_test_support.dart';

void main() {
  const ow = 'oldWorld';
  const player = 'a';
  const enemy = 'b';
  const fullPid = '$ow|p1';
  final topology = navalCoastalProvinceSeaTopology();
  final defaultBuckets = navalCoastalDefaultBuckets();

  group('canonicalSeaZoneTileBucketKey', () {
    test('builds a prefixed bucket key from a local sea-zone id', () {
      expect(canonicalSeaZoneTileBucketKey(ow, 'sea1'), '$ow|sea1');
    });
    test('returns the input unchanged when already prefixed for region', () {
      expect(canonicalSeaZoneTileBucketKey(ow, '$ow|sea1'), '$ow|sea1');
    });
  });

  group('revealProvinceTilesForPlayer', () {
    test('upgrades all province land tiles to fullyVisible for the player', () {
      final out = revealProvinceTilesForPlayer(
        navalCoastalVisibilityGame(
          tileKeysByRegionAndProvince: {
            ow: {
              fullPid: ['$ow|p1|0|0', '$ow|p1|1|0'],
            },
          },
        ),
        const {},
        player,
        fullPid,
      );
      expect(out[player]!['$ow|p1|0|0'], VisibilityLevel.fullyVisible.name);
      expect(out[player]!['$ow|p1|1|0'], VisibilityLevel.fullyVisible.name);
    });

    test('returns the original visibility map when province has no tiles', () {
      final initial = <String, Map<String, String>>{
        player: {'unrelated': VisibilityLevel.fogged.name},
      };
      final out = revealProvinceTilesForPlayer(
        navalCoastalVisibilityGame(),
        initial,
        player,
        fullPid,
      );
      expect(identical(out, initial), isTrue);
    });

    test('does not modify visibility for other players', () {
      final initial = <String, Map<String, String>>{
        enemy: {'$ow|p1|0|0': VisibilityLevel.fogged.name},
      };
      final out = revealProvinceTilesForPlayer(
        navalCoastalVisibilityGame(
          tileKeysByRegionAndProvince: {
            ow: {
              fullPid: ['$ow|p1|0|0'],
            },
          },
        ),
        initial,
        player,
        fullPid,
      );
      expect(out[player]!['$ow|p1|0|0'], VisibilityLevel.fullyVisible.name);
      expect(out[enemy]!['$ow|p1|0|0'], VisibilityLevel.fogged.name);
    });

    test('resolves a legacy local-id keyed bucket (fallback path)', () {
      final out = revealProvinceTilesForPlayer(
        navalCoastalVisibilityGame(
          tileKeysByRegionAndProvince: {
            ow: {
              'p1': ['$ow|p1|0|0'],
            },
          },
        ),
        const {},
        player,
        fullPid,
      );
      expect(out[player]!['$ow|p1|0|0'], VisibilityLevel.fullyVisible.name);
    });
  });

  group('revealTilesAfterMoveToSeaZone', () {
    test('reveals coastal land tiles and all sea water tiles in the zone', () {
      final out = revealTilesAfterMoveToSeaZone(
        game: navalCoastalVisibilityGame(
          tileKeysByRegionAndProvince: defaultBuckets,
        ),
        topology: topology,
        visibilityByTile: const {},
        playerId: player,
        destRegionId: ow,
        destZoneId: 'sea1',
      );
      expect(out[player]!['$ow|p1|0|0'], VisibilityLevel.fullyVisible.name);
      expect(out[player]!['$ow|sea1|1|0'], VisibilityLevel.fullyVisible.name);
      expect(out[player]!.containsKey('$ow|p1|2|2'), isFalse);
    });

    test('returns visibility unchanged when sea zone has no tile bucket', () {
      final out = revealTilesAfterMoveToSeaZone(
        game: navalCoastalVisibilityGame(
          tileKeysByRegionAndProvince: {
            ow: {
              fullPid: ['$ow|p1|0|0'],
            },
          },
        ),
        topology: topology,
        visibilityByTile: const {},
        playerId: player,
        destRegionId: ow,
        destZoneId: 'sea1',
      );
      expect(out[player] ?? const {}, isEmpty);
    });
  });

  group('coastalLandTilesForSeaZone', () {
    test('returns coastal land tiles and sea-water tiles for the zone', () {
      final geometry = coastalLandTilesForSeaZone(
        worldState: navalCoastalVisibilityGame(
          tileKeysByRegionAndProvince: defaultBuckets,
        ).worldState,
        topology: topology,
        regionId: ow,
        zoneId: 'sea1',
      );
      expect(geometry.coastalLandTileKeys, contains('$ow|p1|0|0'));
      expect(geometry.coastalLandTileKeys.contains('$ow|p1|2|2'), isFalse);
      expect(geometry.seaWaterTileKeys, ['$ow|sea1|1|0']);
    });

    test(
      'returns empty coastal and sea-water sets when zone has no bucket',
      () {
        final geometry = coastalLandTilesForSeaZone(
          worldState: navalCoastalVisibilityGame(
            tileKeysByRegionAndProvince: {
              ow: {
                fullPid: ['$ow|p1|0|0'],
              },
            },
          ).worldState,
          topology: topology,
          regionId: ow,
          zoneId: 'sea1',
        );
        expect(geometry.coastalLandTileKeys, isEmpty);
        expect(geometry.seaWaterTileKeys, isEmpty);
      },
    );
  });

  group('coastalLandTileKeysFromNavalPresenceAtSea', () {
    test(
      'returns coastal tiles for non-home fleets at sea owned by player',
      () {
        final out = coastalLandTileKeysFromNavalPresenceAtSea(
          navalCoastalVisibilityGame(
            fleets: [
              Fleet(
                id: 'fleet_${player}_scout',
                ownerId: player,
                seaZoneId: 'sea1',
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
            tileKeysByRegionAndProvince: defaultBuckets,
          ),
          topology,
          player,
        );
        expect(out, contains('$ow|p1|0|0'));
        expect(out.contains('$ow|p1|2|2'), isFalse);
      },
    );

    for (final case_ in _ignoredFleetCases) {
      test(case_.description, () {
        final out = coastalLandTileKeysFromNavalPresenceAtSea(
          navalCoastalVisibilityGame(
            fleets: [case_.fleet],
            tileKeysByRegionAndProvince: {
              ow: {
                fullPid: ['$ow|p1|0|0'],
                '$ow|sea1': ['$ow|sea1|1|0'],
              },
            },
          ),
          topology,
          player,
        );
        expect(out, isEmpty);
      });
    }
  });
}

typedef _IgnoredFleetCase = ({String description, Fleet fleet});

final _ignoredFleetCases = <_IgnoredFleetCase>[
  (
    description: 'ignores the home fleet even when it carries ships at sea',
    fleet: Fleet(
      id: 'fleet_a',
      ownerId: 'a',
      seaZoneId: 'sea1',
      regionId: 'oldWorld',
      shipTypeIds: const ['carrack'],
    ),
  ),
  (
    description: 'ignores fleets owned by other players',
    fleet: Fleet(
      id: 'fleet_b_scout',
      ownerId: 'b',
      seaZoneId: 'sea1',
      regionId: 'oldWorld',
      shipTypeIds: const ['carrack'],
    ),
  ),
  (
    description: 'ignores docked fleets (not at sea)',
    fleet: Fleet(
      id: 'fleet_a_scout',
      ownerId: 'a',
      seaZoneId: null,
      inPortAtProvinceId: 'oldWorld|p1',
      regionId: 'oldWorld',
      shipTypeIds: const ['carrack'],
    ),
  ),
];
