import 'package:colonizethis_world/src/world/fog_resolution.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/world/province_owner_cache.dart';
import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_turn/src/turn/end_of_turn_resolver.dart';

void main() {
group('applySpyRevealTimerDecay', () {
    test(
      'decrements timers for other-faction provinces when timer expires',
      () {
        const ow = 'oldWorld';
        const tileKeyP2 = 'oldWorld|P2|0|0';

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'p1': {tileKeyP2: 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: const {
              ow: {
                '$ow|P2': [tileKeyP2],
              },
            },
            spyRevealTurnsByPlayer: const {
              'p1': {'$ow|P2': 1},
            },
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: false),
          ],
        );

        final (visibility, timers) = applySpyRevealTimerDecay(game);

        // Timer should be removed after reaching zero.
        expect(timers['p1'], isNull);
        expect(visibility['p1']?[tileKeyP2], VisibilityLevel.fogged.name);
      },
    );

    test('never applies timers to own provinces', () {
      const ow = 'oldWorld';
      const tileKeyP1 = 'oldWorld|P1|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {tileKeyP1: 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|P1': [tileKeyP1],
            },
          },
          // Spy timer mistakenly applied to own province; helper must ignore it.
          spyRevealTurnsByPlayer: const {
            'p1': {'$ow|P1': 1},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final (visibility, timers) = applySpyRevealTimerDecay(game);

      // Own-province timer should be dropped without affecting visibility.
      expect(timers['p1'], isNull);
      expect(visibility['p1']?[tileKeyP1], VisibilityLevel.fullyVisible.name);
    });

    test('leaves unknown tiles unchanged when timer expires', () {
      const ow = 'oldWorld';
      const tileKeyP2 = 'oldWorld|P2|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {tileKeyP2: 'unknown'},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|P2': [tileKeyP2],
            },
          },
          spyRevealTurnsByPlayer: const {
            'p1': {'$ow|P2': 1},
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );

      final (visibility, timers) = applySpyRevealTimerDecay(game);

      expect(timers['p1'], isNull);
      expect(visibility['p1']?[tileKeyP2], VisibilityLevel.unknown.name);
    });
  });

  group('applyFogDecay', () {
    test(
      'fogs tiles in other-faction provinces when no Explorer or Spy timer',
      () {
        const ow = 'oldWorld';
        const tileKeyP2 = 'oldWorld|P2|0|0';

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'p1': {tileKeyP2: 'fullyVisible'},
            },
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: false),
          ],
        );

        final nextVisibility = applyFogDecay(game);

        expect(nextVisibility['p1']?[tileKeyP2], VisibilityLevel.fogged.name);
      },
    );

    test(
      'preserves visibility when Explorer is present in other-faction province',
      () {
        const ow = 'oldWorld';
        const tileKeyP2 = 'oldWorld|P2|0|0';

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
              ],
              units: [
                Unit(
                  id: 'explorer1',
                  type: kUnitTypeExplorer,
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P2',
                ),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'p1': {tileKeyP2: 'fullyVisible'},
            },
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: false),
          ],
        );

        final nextVisibility = applyFogDecay(game);

        expect(
          nextVisibility['p1']?[tileKeyP2],
          VisibilityLevel.fullyVisible.name,
        );
      },
    );

    test(
      'fogs other-faction province when no Explorer/Spy remains',
      () {
        const ow = 'oldWorld';
        const tileKeyP2 = 'oldWorld|P2|0|0';

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'p1': {tileKeyP2: 'fullyVisible'},
            },
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: false),
          ],
        );

        final nextVisibility = applyFogDecay(game);

        expect(
          nextVisibility['p1']?[tileKeyP2],
          VisibilityLevel.fogged.name,
        );
      },
    );

    test('does not promote unknown tiles in other-faction province', () {
      const nw = 'newWorld';
      const tileKeyNw = 'newWorld|P2|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: const [
              Province(id: '$nw|P2', regionId: nw, ownerId: 'p2'),
            ],
          ),
          playerVisibilityByTile: const {
            'p1': {tileKeyNw: 'unknown'},
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );

      final nextVisibility = applyFogDecay(game);

      expect(nextVisibility['p1']?[tileKeyNw], VisibilityLevel.unknown.name);
    });

    test('does not change fogged tiles in other-faction province', () {
      const ow = 'oldWorld';
      const tileKeyP2 = 'oldWorld|P2|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {tileKeyP2: 'fogged'},
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );

      final nextVisibility = applyFogDecay(game);

      expect(nextVisibility['p1']?[tileKeyP2], VisibilityLevel.fogged.name);
    });
  });

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

group('applyInitialVisibility coastal sea zone', () {
    test(
      'sets sea zone tiles adjacent to owned province to fullyVisible at game setup',
      () {
        // SPEC/program/fog-and-exploration-resolution.md: coastal sea zone visibility
        // is applied during game setup after initial visibility assignment.
        const ow = 'oldWorld';
        const tileKeySea = 'oldWorld|s1|1|0';
        const tileKeyLand = 'oldWorld|p1|0|0';
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
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'gp1': {
                tileKeyLand: 'fullyVisible',
                tileKeySea: 'fogged', // Initial state before coastal visibility
              },
            },
            tileKeysByRegionAndProvince: const {
              ow: {
                'p1': [tileKeyLand],
                '$ow|s1': [tileKeySea],
              },
            },
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );

        // Apply coastal sea zone visibility as done during game setup
        final inputVis = game.worldState.playerVisibilityByTile;
        final out = applyCoastalSeaZoneFullVisibility(
          game,
          inputVis,
          topology,
          topologyByRegion: {ow: topology},
        );

        // Sea zone adjacent to owned province should be fullyVisible
        expect(out['gp1']![tileKeySea], VisibilityLevel.fullyVisible.name);
        // Land tile should remain fullyVisible
        expect(out['gp1']![tileKeyLand], VisibilityLevel.fullyVisible.name);
      },
    );

    test('coastal sea zone visibility at game setup: multiple GPs', () {
      // Verify that each GP only sees sea zones adjacent to their own provinces
      const ow = 'oldWorld';
      const tileKeyS1 = 'oldWorld|s1|1|0';
      const tileKeyS2 = 'oldWorld|s2|3|0';
      const tileKeyP1 = 'oldWorld|p1|0|0';
      const tileKeyP2 = 'oldWorld|p2|2|0';
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
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'gp2'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {
              tileKeyP1: 'fullyVisible',
              tileKeyP2: 'fogged',
              tileKeyS1: 'fogged',
              tileKeyS2: 'fogged',
            },
            'gp2': {
              tileKeyP1: 'fogged',
              tileKeyP2: 'fullyVisible',
              tileKeyS1: 'fogged',
              tileKeyS2: 'fogged',
            },
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              'p1': [tileKeyP1],
              'p2': [tileKeyP2],
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

      final inputVis = game.worldState.playerVisibilityByTile;
      final out = applyCoastalSeaZoneFullVisibility(
        game,
        inputVis,
        topology,
        topologyByRegion: {ow: topology},
      );

      // GP1: sees s1 (adjacent to p1), not s2
      expect(out['gp1']![tileKeyS1], VisibilityLevel.fullyVisible.name);
      expect(out['gp1']![tileKeyS2], 'fogged');
      // GP2: sees s2 (adjacent to p2), not s1
      expect(out['gp2']![tileKeyS1], 'fogged');
      expect(out['gp2']![tileKeyS2], VisibilityLevel.fullyVisible.name);
    });
  });

group('applyDistantSeaZoneFogRevert', () {
    test(
      'fogs open-ocean sea tiles when no owned coast and no fleet at sea',
      () {
        const ow = 'oldWorld';
        const tileSea2 = 'oldWorld|s2|0|0';
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
            TopologyNode(
              id: 's2',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'p1', id2: 's1'),
            TopologyEdge(id1: 's1', id2: 's2'),
          ],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 0,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: const {
              ow: {
                '$ow|s1': ['oldWorld|s1|0|0'],
                '$ow|s2': [tileSea2],
              },
            },
            fleets: const [],
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );
        final inputVis = <String, Map<String, String>>{
          'gp1': {tileSea2: VisibilityLevel.fullyVisible.name},
        };

        final out = applyDistantSeaZoneFogRevert(game, inputVis, topology);

        expect(out['gp1']![tileSea2], VisibilityLevel.fogged.name);
      },
    );

    test('does not fog sea zone while player fleet is at sea there', () {
      const ow = 'oldWorld';
      const tileSea2 = 'oldWorld|s2|0|0';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 's1', regionId: ow, type: TopologyNodeType.seaZone),
          TopologyNode(id: 's2', regionId: ow, type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 's1'),
          TopologyEdge(id1: 's1', id2: 's2'),
        ],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|s2': [tileSea2],
            },
          },
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'gp1',
              seaZoneId: 's2',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );
      final inputVis = <String, Map<String, String>>{
        'gp1': {tileSea2: VisibilityLevel.fullyVisible.name},
      };

      final out = applyDistantSeaZoneFogRevert(game, inputVis, topology);

      expect(out['gp1']![tileSea2], VisibilityLevel.fullyVisible.name);
    });

    test('other player fleet at sea does not block distant fog revert', () {
      const ow = 'oldWorld';
      const tileSea2 = 'oldWorld|s2|0|0';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 's1', regionId: ow, type: TopologyNodeType.seaZone),
          TopologyNode(id: 's2', regionId: ow, type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 's1'),
          TopologyEdge(id1: 's1', id2: 's2'),
        ],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|s2': [tileSea2],
            },
          },
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'gp2',
              seaZoneId: 's2',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        ],
      );
      final inputVis = <String, Map<String, String>>{
        'gp1': {tileSea2: VisibilityLevel.fullyVisible.name},
      };

      final out = applyDistantSeaZoneFogRevert(game, inputVis, topology);

      expect(out['gp1']![tileSea2], VisibilityLevel.fogged.name);
    });

    test(
      'GitHub #2023: distant fog revert for New World does not throw when same '
      'player has Old World fleet at sea (cross-region scan)',
      () {
        const ow = kRegionOldWorld;
        const nw = kRegionNewWorld;
        const tileNwSea = 'newWorld|nwSea|0|0';
        final topologyOw = MapTopology(
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
            TopologyNode(
              id: 's2',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'p1', id2: 's1'),
            TopologyEdge(id1: 's1', id2: 's2'),
          ],
        );
        final topologyNw = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'nwSea',
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [],
        );
        final combined = MapTopology(
          nodes: [...topologyOw.nodes, ...topologyNw.nodes],
          edges: topologyOw.edges,
        );
        final game = Game(
          id: 'g_fog_2023',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 0,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                '$ow|s2': const ['oldWorld|s2|0|0'],
              },
              nw: {
                '$nw|nwSea': [tileNwSea],
              },
            },
            fleets: [
              Fleet(
                id: 'f_ow',
                ownerId: 'gp1',
                seaZoneId: 's2',
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );
        final inputVis = <String, Map<String, String>>{
          'gp1': {tileNwSea: VisibilityLevel.fullyVisible.name},
        };

        final out = applyDistantSeaZoneFogRevert(
          game,
          inputVis,
          combined,
          topologyByRegion: {ow: topologyOw, nw: topologyNw},
        );

        expect(out['gp1']![tileNwSea], VisibilityLevel.fogged.name);
      },
    );

    test('fogs distant sea when player fleet is in port only (not at sea)', () {
      const ow = 'oldWorld';
      const tileSea2 = 'oldWorld|s2|0|0';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 's1', regionId: ow, type: TopologyNodeType.seaZone),
          TopologyNode(id: 's2', regionId: ow, type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 's1'),
          TopologyEdge(id1: 's1', id2: 's2'),
        ],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|s2': [tileSea2],
            },
          },
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'gp1',
              regionId: ow,
              inPortAtProvinceId: '$ow|p1',
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );
      final inputVis = <String, Map<String, String>>{
        'gp1': {tileSea2: VisibilityLevel.fullyVisible.name},
      };

      final out = applyDistantSeaZoneFogRevert(game, inputVis, topology);

      expect(out['gp1']![tileSea2], VisibilityLevel.fogged.name);
    });

    test('does not change unknown water tiles', () {
      const ow = 'oldWorld';
      const tileSea2 = 'oldWorld|s2|0|0';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 's2', regionId: ow, type: TopologyNodeType.seaZone),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|s2': [tileSea2],
            },
          },
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );
      final inputVis = <String, Map<String, String>>{
        'gp1': {tileSea2: VisibilityLevel.unknown.name},
      };

      final out = applyDistantSeaZoneFogRevert(game, inputVis, topology);

      expect(out['gp1']![tileSea2], VisibilityLevel.unknown.name);
    });
  });

group('applyDistantSeaZoneFogRevert end-of-turn integration', () {
    test(
      'coastal pass after distant restores shore-adjacent sea from fogged',
      () {
        const ow = 'oldWorld';
        const tileS1 = 'oldWorld|s1|0|0';
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
              turnNumber: 0,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: const {
              ow: {
                '$ow|s1': [tileS1],
              },
            },
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );
        final afterDistant = applyDistantSeaZoneFogRevert(game, {
          'gp1': {tileS1: VisibilityLevel.fogged.name},
        }, topology);
        expect(afterDistant['gp1']![tileS1], VisibilityLevel.fogged.name);
        final afterCoastal = applyCoastalSeaZoneFullVisibility(
          game,
          afterDistant,
          topology,
        );
        expect(afterCoastal['gp1']![tileS1], VisibilityLevel.fullyVisible.name);
      },
    );

    test(
      'runEndOfTurnPhase fogs distant sea then coastal restores owned shore',
      () {
        const ow = 'oldWorld';
        const tileS1 = 'oldWorld|s1|0|0';
        const tileS2 = 'oldWorld|s2|0|0';
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
            TopologyNode(
              id: 's2',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'p1', id2: 's1'),
            TopologyEdge(id1: 's1', id2: 's2'),
          ],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 5,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: {
              'gp1': {
                tileS1: VisibilityLevel.fullyVisible.name,
                tileS2: VisibilityLevel.fullyVisible.name,
              },
            },
            tileKeysByRegionAndProvince: const {
              ow: {
                '$ow|s1': [tileS1],
                '$ow|s2': [tileS2],
              },
            },
            fleets: const [],
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );

        final next = runEndOfTurnPhase(game, topology: topology);

        expect(next.worldState.turnState.turnNumber, 6);
        expect(next.worldState.turnState.phase, TurnPhase.orders);
        expect(
          next.worldState.playerVisibilityByTile['gp1']![tileS2],
          VisibilityLevel.fogged.name,
        );
        expect(
          next.worldState.playerVisibilityByTile['gp1']![tileS1],
          VisibilityLevel.fullyVisible.name,
        );
      },
    );

    test('GitHub #2023: runEndOfTurnPhase completes when OW fleet at sea and '
        'topologyByRegion splits regions (distant fog revert path)', () {
      const ow = kRegionOldWorld;
      const nw = kRegionNewWorld;
      const tileNwSea = 'newWorld|nwSea|0|0';
      final topologyOw = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 's1', regionId: ow, type: TopologyNodeType.seaZone),
          TopologyNode(id: 's2', regionId: ow, type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 's1'),
          TopologyEdge(id1: 's1', id2: 's2'),
        ],
      );
      final topologyNw = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'nwSea',
            regionId: nw,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final combined = MapTopology(
        nodes: [...topologyOw.nodes, ...topologyNw.nodes],
        edges: topologyOw.edges,
      );
      final game = Game(
        id: 'g_eot_2023',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 5),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            'gp1': {
              'oldWorld|p1|0|0': VisibilityLevel.fullyVisible.name,
              'oldWorld|s1|0|0': VisibilityLevel.fullyVisible.name,
              'oldWorld|s2|0|0': VisibilityLevel.fullyVisible.name,
              tileNwSea: VisibilityLevel.fullyVisible.name,
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': const ['oldWorld|p1|0|0'],
              '$ow|s1': const ['oldWorld|s1|0|0'],
              '$ow|s2': const ['oldWorld|s2|0|0'],
            },
            nw: {
              '$nw|nwSea': [tileNwSea],
            },
          },
          fleets: [
            Fleet(
              id: 'f_ow',
              ownerId: 'gp1',
              seaZoneId: 's2',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );

      final next = runEndOfTurnPhase(
        game,
        topology: combined,
        topologyByRegion: {ow: topologyOw, nw: topologyNw},
      );

      expect(next.worldState.turnState.turnNumber, 6);
      expect(next.worldState.turnState.phase, TurnPhase.orders);
      expect(
        next.worldState.playerVisibilityByTile['gp1']![tileNwSea],
        VisibilityLevel.fogged.name,
      );
    });

    test(
      'runEndOfTurnPhase leaves unknown New World land unknown (turn 0→1)',
      () {
        const ow = 'oldWorld';
        const nw = 'newWorld';
        const nwTile = 'newWorld|P2|0|0';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.endOfTurn,
              turnNumber: 0,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: RegionData(
              provinces: const [
                Province(id: '$nw|P2', regionId: nw, ownerId: 'p2'),
              ],
            ),
            playerVisibilityByTile: {
              'gp1': {
                'oldWorld|p1|0|0': VisibilityLevel.fullyVisible.name,
                nwTile: VisibilityLevel.unknown.name,
              },
            },
            tileKeysByRegionAndProvince: {
              ow: {
                'p1': ['oldWorld|p1|0|0'],
              },
              nw: {
                'P2': [nwTile],
              },
            },
            fleets: const [],
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: false),
          ],
        );

        final next = runEndOfTurnPhase(game, topology: topology);

        expect(next.worldState.turnState.turnNumber, 1);
        expect(
          next.worldState.playerVisibilityByTile['gp1']![nwTile],
          VisibilityLevel.unknown.name,
        );
      },
    );
  });

}
