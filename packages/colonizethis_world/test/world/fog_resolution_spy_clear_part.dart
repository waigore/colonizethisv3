part of 'fog_resolution_test.dart';

void _fog_resolution_spy_clear_testTests() {
group('clearSpyRevealTimersForProvince', () {
    test('removes timers only for the given player and province', () {
      const ow = 'oldWorld';
      final existing = <String, Map<String, int>>{
        'p1': {'$ow|P1': 3, '$ow|P2': 2},
        'p2': {'$ow|P2': 4},
      };

      final next = clearSpyRevealTimersForProvince(existing, 'p1', '$ow|P2');

      expect(next['p1'], isNotNull);
      expect(next['p1']!.containsKey('$ow|P1'), isTrue);
      expect(next['p1']!.containsKey('$ow|P2'), isFalse);
      // Other players' timers untouched.
      expect(next['p2']!.containsKey('$ow|P2'), isTrue);
    });

    test('drops empty inner map when last timer is removed', () {
      const ow = 'oldWorld';
      final existing = <String, Map<String, int>>{
        'p1': {'$ow|P2': 1},
        'p2': {'$ow|P2': 2},
      };

      final next = clearSpyRevealTimersForProvince(existing, 'p1', '$ow|P2');

      expect(next.containsKey('p1'), isFalse);
      expect(next['p2']!.containsKey('$ow|P2'), isTrue);
    });
  });

  group('clearSpyRevealTimersForProvinceOwnershipTransfer', () {
    test('removes timers for old and new owner only', () {
      const ow = 'oldWorld';
      final existing = <String, Map<String, int>>{
        'a': {'$ow|P1': 3},
        'b': {'$ow|P1': 2},
        'c': {'$ow|P2': 1},
      };

      final next = clearSpyRevealTimersForProvinceOwnershipTransfer(
        existing,
        '$ow|P1',
        'a',
        'b',
      );

      expect(next['a']?['$ow|P1'], isNull);
      expect(next['b']?['$ow|P1'], isNull);
      expect(next['c']!['$ow|P2'], 1);
    });
  });

  group('applyProvinceOwnershipChangeVisibility', () {
    test('fully visible for new owner and downgrades former owner', () {
      const ow = 'oldWorld';
      const pid = '$ow|P1';
      const tileKey = '$ow|P1|0|0';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [Province(id: pid, regionId: ow, ownerId: 'a')],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'a': {tileKey: 'fullyVisible'},
            'b': {},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              pid: [tileKey],
            },
          },
        ),
        players: const [
          Player(id: 'a', displayName: 'A', isHuman: true),
          Player(id: 'b', displayName: 'B', isHuman: true),
        ],
      );

      final out = applyProvinceOwnershipChangeVisibility(game, pid, 'a', 'b');

      expect(out.visibilitySummary.tilesSetFullyVisibleForNewOwner, 1);
      expect(out.visibilitySummary.tilesDowngradedForFormerOwner, 1);
      expect(
        out.game.worldState.playerVisibilityByTile['b']?[tileKey],
        VisibilityLevel.fullyVisible.name,
      );
      expect(
        out.game.worldState.playerVisibilityByTile['a']?[tileKey],
        VisibilityLevel.fogged.name,
      );
    });
  });

  group('applyCoastalSeaZoneFullVisibility', () {
    test(
      'sets sea zone tiles adjacent to owned coastal province to fullyVisible for that GP',
      () {
        const ow = 'oldWorld';
        const tileKeySea = 'oldWorld|s1|1|0';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 's1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'gp1': {tileKeySea: 'fogged'},
            },
            tileKeysByRegionAndProvince: const {
              ow: {
                'p1': ['oldWorld|p1|0|0'],
                '$ow|s1': [tileKeySea],
              },
            },
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );
        final inputVis = <String, Map<String, String>>{
          'gp1': {tileKeySea: 'fogged'},
        };

        final out = applyCoastalSeaZoneFullVisibility(game, inputVis, topology);

        expect(out['gp1']![tileKeySea], VisibilityLevel.fullyVisible.name);
      },
    );

    test(
      'does not set sea zone tiles when GP has no owned province adjacent to that sea zone',
      () {
        const ow = 'oldWorld';
        const tileKeySea = 'oldWorld|s1|1|0';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 's1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [], // p1 not adjacent to s1
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'gp1': {tileKeySea: 'fogged'},
            },
            tileKeysByRegionAndProvince: const {
              ow: {
                '$ow|s1': [tileKeySea],
              },
            },
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );
        final inputVis = <String, Map<String, String>>{
          'gp1': {tileKeySea: 'fogged'},
        };

        final out = applyCoastalSeaZoneFullVisibility(game, inputVis, topology);

        expect(out['gp1']![tileKeySea], 'fogged');
      },
    );

    test(
      'each GP gets full visibility only for sea zones adjacent to their own provinces',
      () {
        const ow = 'oldWorld';
        const tileKeyS1 = 'oldWorld|s1|1|0';
        const tileKeyS2 = 'oldWorld|s2|3|0';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 's1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 's2',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'p1', id2: 's1'),
            TopologyEdge(id1: 'p2', id2: 's2'),
          ],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
                Province(id: '$ow|p2', regionId: ow, ownerId: 'gp2'),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'gp1': {tileKeyS1: 'fogged', tileKeyS2: 'fogged'},
              'gp2': {tileKeyS1: 'fogged', tileKeyS2: 'fogged'},
            },
            tileKeysByRegionAndProvince: const {
              ow: {
                'p1': ['oldWorld|p1|0|0'],
                'p2': ['oldWorld|p2|2|0'],
                '$ow|s1': [tileKeyS1],
                '$ow|s2': [tileKeyS2],
              },
            },
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          ],
        );
        final inputVis = <String, Map<String, String>>{
          'gp1': {tileKeyS1: 'fogged', tileKeyS2: 'fogged'},
          'gp2': {tileKeyS1: 'fogged', tileKeyS2: 'fogged'},
        };

        final out = applyCoastalSeaZoneFullVisibility(game, inputVis, topology);

        expect(out['gp1']![tileKeyS1], VisibilityLevel.fullyVisible.name);
        expect(out['gp1']![tileKeyS2], 'fogged');
        expect(out['gp2']![tileKeyS1], 'fogged');
        expect(out['gp2']![tileKeyS2], VisibilityLevel.fullyVisible.name);
      },
    );

    // Phase 6b slice 16 (SPEC/program/worldstate-projection.md; Refs #3393):
    // the migrated helper drives full visibility from
    // ProvinceOwnerCache.provincesOwnedByInRegion, so only the GP's own
    // provinces (not a non-GP minor's adjacent province) reveal their sea zones.
    test(
      'slice 16: only ProvinceOwnerCache-owned provinces drive sea-zone '
      'visibility (non-owned adjacent province excluded)',
      () {
        const ow = 'oldWorld';
        const tileKeyS1 = 'oldWorld|s1|1|0';
        const tileKeyS2 = 'oldWorld|s2|3|0';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 's1', regionId: ow, type: TopologyNodeType.seaZone),
            TopologyNode(id: 's2', regionId: ow, type: TopologyNodeType.seaZone),
          ],
          edges: const [
            TopologyEdge(id1: 'p1', id2: 's1'),
            TopologyEdge(id1: 'p2', id2: 's2'),
          ],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
                // Owned by a non-GP minor adjacent to s2: must not reveal s2 for gp1.
                Province(id: '$ow|p2', regionId: ow, ownerId: 'm1'),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'gp1': {tileKeyS1: 'fogged', tileKeyS2: 'fogged'},
            },
            tileKeysByRegionAndProvince: const {
              ow: {
                'p1': ['oldWorld|p1|0|0'],
                'p2': ['oldWorld|p2|2|0'],
                '$ow|s1': [tileKeyS1],
                '$ow|s2': [tileKeyS2],
              },
            },
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );

        // Projection parity: gp1 owns exactly p1 in the old world.
        final ownedByGp1 = ProvinceOwnerCache.of(
          game.worldState,
        ).provincesOwnedByInRegion('gp1', ow).map((p) => p.id).toList();
        expect(ownedByGp1, ['$ow|p1']);

        final inputVis = <String, Map<String, String>>{
          'gp1': {tileKeyS1: 'fogged', tileKeyS2: 'fogged'},
        };

        final out = applyCoastalSeaZoneFullVisibility(game, inputVis, topology);

        // s1 (adjacent to gp1-owned p1) is revealed; s2 (adjacent to m1-owned
        // p2) stays fogged — identical to the pre-migration owner scan.
        expect(out['gp1']![tileKeyS1], VisibilityLevel.fullyVisible.name);
        expect(out['gp1']![tileKeyS2], 'fogged');
      },
    );
  });

}
