import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/world/naval_coastal_visibility.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  const ow = 'oldWorld';
  const player = 'a';
  const enemy = 'b';
  const fullPid = '$ow|p1';

  Game gameWithBuckets({
    Map<String, Map<String, List<String>>>?
    tileKeysByRegionAndProvince,
    List<Fleet> fleets = const [],
    List<Province> oldWorldProvinces = const [],
  }) {
    return Game(
      id: 'test_game',
      worldState: WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: RegionData(provinces: oldWorldProvinces),
        newWorld: const RegionData(),
        fleets: fleets,
        tileKeysByRegionAndProvince:
            tileKeysByRegionAndProvince ?? const {},
      ),
      players: const [Player(id: player, displayName: 'A', isHuman: true)],
    );
  }

  group('canonicalSeaZoneTileBucketKey', () {
    test('builds a prefixed bucket key from a local sea-zone id', () {
      expect(
        canonicalSeaZoneTileBucketKey(ow, 'sea1'),
        '$ow|sea1',
      );
    });

    test('returns the input unchanged when already prefixed for region', () {
      expect(
        canonicalSeaZoneTileBucketKey(ow, '$ow|sea1'),
        '$ow|sea1',
      );
    });
  });

  // `landTileKeysForProvinceBucket` moved to the canonical
  // `province_lookup.dart` (Refs #3403 Phase 1). Strict + opt-in
  // `allowLocalIdFallback` behaviour is covered in
  // `test/world/province_lookup_standalone_test.dart`. The naval reveal paths
  // below still exercise the fallback transitively via
  // `revealProvinceTilesForPlayer` (local-id bucket case).

  group('revealProvinceTilesForPlayer', () {
    test('upgrades all province land tiles to fullyVisible for the player', () {
      final game = gameWithBuckets(
        tileKeysByRegionAndProvince: const {
          ow: {
            fullPid: ['$ow|p1|0|0', '$ow|p1|1|0'],
          },
        },
      );

      final out = revealProvinceTilesForPlayer(
        game,
        const <String, Map<String, String>>{},
        player,
        fullPid,
      );

      expect(out[player]!['$ow|p1|0|0'], VisibilityLevel.fullyVisible.name);
      expect(out[player]!['$ow|p1|1|0'], VisibilityLevel.fullyVisible.name);
    });

    test('returns the original visibility map when province has no tiles', () {
      final game = gameWithBuckets();
      final initial = <String, Map<String, String>>{
        player: {'unrelated': VisibilityLevel.fogged.name},
      };

      final out = revealProvinceTilesForPlayer(game, initial, player, fullPid);

      expect(identical(out, initial), isTrue);
    });

    test('does not modify visibility for other players', () {
      final game = gameWithBuckets(
        tileKeysByRegionAndProvince: const {
          ow: {
            fullPid: ['$ow|p1|0|0'],
          },
        },
      );
      final initial = <String, Map<String, String>>{
        enemy: {'$ow|p1|0|0': VisibilityLevel.fogged.name},
      };

      final out = revealProvinceTilesForPlayer(game, initial, player, fullPid);

      expect(out[player]!['$ow|p1|0|0'], VisibilityLevel.fullyVisible.name);
      expect(out[enemy]!['$ow|p1|0|0'], VisibilityLevel.fogged.name);
    });

    test('resolves a legacy local-id keyed bucket (fallback path)', () {
      // Fixture/legacy map keyed by local id only; the naval reveal path opts
      // into the canonical helper's `allowLocalIdFallback` (Refs #3403 Phase 1).
      final game = gameWithBuckets(
        tileKeysByRegionAndProvince: const {
          ow: {
            'p1': ['$ow|p1|0|0'],
          },
        },
      );
      final initial = <String, Map<String, String>>{};

      final out = revealProvinceTilesForPlayer(game, initial, player, fullPid);

      expect(out[player]!['$ow|p1|0|0'], VisibilityLevel.fullyVisible.name);
    });
  });

  group('revealTilesAfterMoveToSeaZone', () {
    final topology = MapTopology(
      nodes: const [
        TopologyNode(
          id: 'p1',
          regionId: ow,
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'sea1',
          regionId: ow,
          type: TopologyNodeType.seaZone,
        ),
      ],
      edges: const [TopologyEdge(id1: 'sea1', id2: 'p1')],
    );

    test('reveals coastal land tiles and all sea water tiles in the zone', () {
      final game = gameWithBuckets(
        tileKeysByRegionAndProvince: const {
          ow: {
            fullPid: ['$ow|p1|0|0', '$ow|p1|2|2'],
            '$ow|sea1': ['$ow|sea1|1|0'],
          },
        },
      );

      final out = revealTilesAfterMoveToSeaZone(
        game: game,
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
      final game = gameWithBuckets(
        tileKeysByRegionAndProvince: const {
          ow: {
            fullPid: ['$ow|p1|0|0'],
          },
        },
      );

      final out = revealTilesAfterMoveToSeaZone(
        game: game,
        topology: topology,
        visibilityByTile: const {},
        playerId: player,
        destRegionId: ow,
        destZoneId: 'sea1',
      );

      expect(out[player] ?? const {}, isEmpty);
    });
  });

  group('coastalLandTileKeysFromNavalPresenceAtSea', () {
    final topology = MapTopology(
      nodes: const [
        TopologyNode(
          id: 'p1',
          regionId: ow,
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'sea1',
          regionId: ow,
          type: TopologyNodeType.seaZone,
        ),
      ],
      edges: const [TopologyEdge(id1: 'sea1', id2: 'p1')],
    );

    test('returns coastal tiles for non-home fleets at sea owned by player', () {
      final game = gameWithBuckets(
        fleets: [
          Fleet(
            id: 'fleet_${player}_scout',
            ownerId: player,
            seaZoneId: 'sea1',
            regionId: ow,
            shipTypeIds: const ['carrack'],
          ),
        ],
        tileKeysByRegionAndProvince: const {
          ow: {
            fullPid: ['$ow|p1|0|0', '$ow|p1|2|2'],
            '$ow|sea1': ['$ow|sea1|1|0'],
          },
        },
      );

      final out = coastalLandTileKeysFromNavalPresenceAtSea(
        game,
        topology,
        player,
      );

      expect(out, contains('$ow|p1|0|0'));
      expect(out.contains('$ow|p1|2|2'), isFalse);
    });

    test('ignores the home fleet even when it carries ships at sea', () {
      final game = gameWithBuckets(
        fleets: [
          Fleet(
            id: 'fleet_$player',
            ownerId: player,
            seaZoneId: 'sea1',
            regionId: ow,
            shipTypeIds: const ['carrack'],
          ),
        ],
        tileKeysByRegionAndProvince: const {
          ow: {
            fullPid: ['$ow|p1|0|0'],
            '$ow|sea1': ['$ow|sea1|1|0'],
          },
        },
      );

      final out = coastalLandTileKeysFromNavalPresenceAtSea(
        game,
        topology,
        player,
      );

      expect(out, isEmpty);
    });

    test('ignores fleets owned by other players', () {
      final game = gameWithBuckets(
        fleets: [
          Fleet(
            id: 'fleet_${enemy}_scout',
            ownerId: enemy,
            seaZoneId: 'sea1',
            regionId: ow,
            shipTypeIds: const ['carrack'],
          ),
        ],
        tileKeysByRegionAndProvince: const {
          ow: {
            fullPid: ['$ow|p1|0|0'],
            '$ow|sea1': ['$ow|sea1|1|0'],
          },
        },
      );

      final out = coastalLandTileKeysFromNavalPresenceAtSea(
        game,
        topology,
        player,
      );

      expect(out, isEmpty);
    });

    test('ignores docked fleets (not at sea)', () {
      final game = gameWithBuckets(
        fleets: [
          Fleet(
            id: 'fleet_${player}_scout',
            ownerId: player,
            seaZoneId: null,
            inPortAtProvinceId: fullPid,
            regionId: ow,
            shipTypeIds: const ['carrack'],
          ),
        ],
        tileKeysByRegionAndProvince: const {
          ow: {
            fullPid: ['$ow|p1|0|0'],
            '$ow|sea1': ['$ow|sea1|1|0'],
          },
        },
      );

      final out = coastalLandTileKeysFromNavalPresenceAtSea(
        game,
        topology,
        player,
      );

      expect(out, isEmpty);
    });
  });
}
