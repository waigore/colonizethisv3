// Asserts the incremental candidate validation primitive returns the same
// accept/reject decision for stateless candidate types (move, army move,
// naval move, naval mission) as the existing OrderEngine full-pass probe.
// SPEC/program/order-suggestions.md § Incremental candidate validation.
// SPEC/program/order-engine.md § Validation (candidate-probe context).
// Refs #2237.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  group('IncrementalCandidateValidator equivalence (Refs #2237)', () {
    bool fullPassMoveAccepted(
      Game game,
      MapTopology topology,
      String playerId,
      Orders basePrefix,
      MoveOrder candidate,
    ) {
      final engine = OrderEngine(initialOrders: basePrefix);
      return engine
          .addMoveOrderWithContext(game, topology, playerId, candidate)
          .isAccepted;
    }

    bool fullPassArmyMoveAccepted(
      Game game,
      MapTopology topology,
      String playerId,
      Orders basePrefix,
      ArmyMoveOrder candidate,
    ) {
      final merged = applyArmyMoveOrderForPlayer(basePrefix, playerId, candidate);
      final engine = OrderEngine(initialOrders: merged);
      final results =
          engine.validatePlayerOrdersWithContext(game, topology, playerId);
      if (results.isEmpty) return false;
      return results.every((r) => r.isAccepted);
    }

    bool fullPassNavalMoveAccepted(
      Game game,
      MapTopology topology,
      String playerId,
      Orders basePrefix,
      NavalMoveOrder candidate,
    ) {
      final engine = OrderEngine(initialOrders: basePrefix);
      return engine
          .addNavalMoveOrderWithContext(game, topology, playerId, candidate)
          .isAccepted;
    }

    bool fullPassNavalMissionAccepted(
      Game game,
      MapTopology topology,
      String playerId,
      Orders basePrefix,
      NavalMissionOrder candidate,
    ) {
      final engine = OrderEngine(initialOrders: basePrefix);
      return engine
          .addNavalMissionOrderWithContext(game, topology, playerId, candidate)
          .isAccepted;
    }

    void expectMoveEquivalent({
      required Game game,
      required MapTopology topology,
      required String playerId,
      required Orders basePrefix,
      required MoveOrder candidate,
      required String label,
    }) {
      final fullPass = fullPassMoveAccepted(
        game,
        topology,
        playerId,
        basePrefix,
        candidate,
      );
      final incremental = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: playerId,
        basePrefix: basePrefix,
      ).isMoveAccepted(candidate);
      expect(
        incremental,
        equals(fullPass),
        reason:
            'Move candidate "$label" diverged: incremental=$incremental, '
            'fullPass=$fullPass',
      );
    }

    void expectArmyMoveEquivalent({
      required Game game,
      required MapTopology topology,
      required String playerId,
      required Orders basePrefix,
      required ArmyMoveOrder candidate,
      required String label,
    }) {
      final fullPass = fullPassArmyMoveAccepted(
        game,
        topology,
        playerId,
        basePrefix,
        candidate,
      );
      final incremental = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: playerId,
        basePrefix: basePrefix,
      ).isArmyMoveAccepted(candidate);
      expect(
        incremental,
        equals(fullPass),
        reason:
            'Army move candidate "$label" diverged: incremental=$incremental, '
            'fullPass=$fullPass',
      );
    }

    void expectNavalMoveEquivalent({
      required Game game,
      required MapTopology topology,
      required String playerId,
      required Orders basePrefix,
      required NavalMoveOrder candidate,
      required String label,
    }) {
      final fullPass = fullPassNavalMoveAccepted(
        game,
        topology,
        playerId,
        basePrefix,
        candidate,
      );
      final incremental = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: playerId,
        basePrefix: basePrefix,
      ).isNavalMoveAccepted(candidate);
      expect(
        incremental,
        equals(fullPass),
        reason:
            'Naval move candidate "$label" diverged: '
            'incremental=$incremental, fullPass=$fullPass',
      );
    }

    void expectNavalMissionEquivalent({
      required Game game,
      required MapTopology topology,
      required String playerId,
      required Orders basePrefix,
      required NavalMissionOrder candidate,
      required String label,
    }) {
      final fullPass = fullPassNavalMissionAccepted(
        game,
        topology,
        playerId,
        basePrefix,
        candidate,
      );
      final incremental = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: playerId,
        basePrefix: basePrefix,
      ).isNavalMissionAccepted(candidate);
      expect(
        incremental,
        equals(fullPass),
        reason:
            'Naval mission candidate "$label" diverged: '
            'incremental=$incremental, fullPass=$fullPass',
      );
    }

    // ---- Move fixtures ----

    Game moveCorpusGame() {
      const ow = 'oldWorld';
      return Game(
        id: 'g_move_eq',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P3', regionId: ow, ownerId: 'p2'),
              Province(id: '$ow|P4', regionId: ow, ownerId: 'minor1'),
            ],
            units: [
              Unit(
                id: 'u_builder',
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: '$ow|P1|0|0',
              ),
              Unit(
                id: 'u_explorer',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: '$ow|P1|0|0',
              ),
              Unit(
                id: 'u_spy',
                type: kUnitTypeSpy,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: '$ow|P1|0|0',
              ),
              Unit(
                id: 'u_pikemen',
                type: 'pikemen',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|P1': ['$ow|P1|0|0'],
              '$ow|P2': ['$ow|P2|0|0'],
              '$ow|P3': ['$ow|P3|0|0'],
              '$ow|P4': ['$ow|P4|0|0'],
            },
          },
          playerVisibilityByTile: const {
            'p1': {
              '$ow|P1|0|0': 'fullyVisible',
              '$ow|P2|0|0': 'fogged',
              '$ow|P3|0|0': 'fogged',
              '$ow|P4|0|0': 'fogged',
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
      );
    }

    MapTopology moveCorpusTopology() {
      const ow = 'oldWorld';
      return MapTopology(
        nodes: const [
          TopologyNode(id: '$ow|P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: '$ow|P2', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: '$ow|P3', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: '$ow|P4', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );
    }

    test('move: builder onto own province (accepted)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(
          unitId: 'u_builder',
          destinationTileKey: 'oldWorld|P2|0|0',
        ),
        label: 'builder->own province',
      );
    });

    test('move: builder onto other GP province (rejected)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(
          unitId: 'u_builder',
          destinationTileKey: 'oldWorld|P3|0|0',
        ),
        label: 'builder->other GP province',
      );
    });

    test('move: explorer onto Minor province (accepted)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(
          unitId: 'u_explorer',
          destinationTileKey: 'oldWorld|P4|0|0',
        ),
        label: 'explorer->minor province',
      );
    });

    test('move: spy onto other GP province (accepted)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(
          unitId: 'u_spy',
          destinationTileKey: 'oldWorld|P3|0|0',
        ),
        label: 'spy->other GP province',
      );
    });

    test('move: military regiment via MoveOrder (rejected)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(
          unitId: 'u_pikemen',
          destinationTileKey: 'oldWorld|P2|0|0',
        ),
        label: 'pikemen via MoveOrder',
      );
    });

    test('move: missing unit (rejected)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(
          unitId: 'unknown_unit',
          destinationTileKey: 'oldWorld|P2|0|0',
        ),
        label: 'unknown unit',
      );
    });

    test('move: empty destination tile (rejected)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(
          unitId: 'u_builder',
          destinationTileKey: '',
        ),
        label: 'empty destination',
      );
    });

    test('move: rejected because basePrefix has work order for same unit '
        '(move XOR work cascade)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      // basePrefix has a work order for u_explorer; adding a move for the
      // same unit invalidates that work via the XOR rule. Full-pass returns
      // false (cascade); incremental must also return false.
      final basePrefix = Orders(
        workOrdersByPlayerId: {
          'p1': [
            const WorkOrder(
              unitId: 'u_explorer',
              target: 'explore',
              targetTileKey: 'oldWorld|P2|0|0',
            ),
          ],
        },
      );
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: basePrefix,
        candidate: const MoveOrder(
          unitId: 'u_explorer',
          destinationTileKey: 'oldWorld|P2|0|0',
        ),
        label: 'move w/ existing work for same unit',
      );
    });

    test('move: with non-empty accepted basePrefix (accepted)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      // basePrefix already contains an accepted move for explorer; candidate is
      // for builder (independent) and should still be accepted.
      final basePrefix = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(
              unitId: 'u_explorer',
              destinationTileKey: 'oldWorld|P2|0|0',
            ),
          ],
        },
      );
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: basePrefix,
        candidate: const MoveOrder(
          unitId: 'u_builder',
          destinationTileKey: 'oldWorld|P2|0|0',
        ),
        label: 'builder w/ prior explorer move in basePrefix',
      );
    });

    // ---- Army move fixtures ----

    Game armyCorpusGame() {
      const ow = 'oldWorld';
      Army field(String id, String stationed, String regimentId) => Army(
        id: id,
        ownerId: 'p1',
        regionId: ow,
        stationedProvinceId: stationed,
        regimentUnitIds: [regimentId],
        isHomeArmy: false,
      );
      return Game(
        id: 'g_army_eq',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P3', regionId: ow, ownerId: 'p2'),
              Province(id: '$ow|P4', regionId: ow, ownerId: 'minor1'),
            ],
            units: [
              Unit(id: 'r1', type: 'pikemen', ownerId: 'p1', locationProvinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
          armies: [field('field_a', '$ow|P1', 'r1')],
          playerVisibilityByTile: const {
            'p1': {
              '$ow|P1|0|0': 'fullyVisible',
              '$ow|P2|0|0': 'fogged',
              '$ow|P3|0|0': 'fogged',
              '$ow|P4|0|0': 'fogged',
            },
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|P1': ['$ow|P1|0|0'],
              '$ow|P2': ['$ow|P2|0|0'],
              '$ow|P3': ['$ow|P3|0|0'],
              '$ow|P4': ['$ow|P4|0|0'],
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: const [],
      );
    }

    MapTopology armyCorpusTopology() {
      const ow = 'oldWorld';
      return MapTopology(
        nodes: const [
          TopologyNode(id: '$ow|P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: '$ow|P2', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: '$ow|P3', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: '$ow|P4', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: '$ow|P1', id2: '$ow|P2'),
          TopologyEdge(id1: '$ow|P1', id2: '$ow|P3'),
          TopologyEdge(id1: '$ow|P1', id2: '$ow|P4'),
        ],
      );
    }

    test('army move: into own adjacent province (accepted)', () {
      final game = armyCorpusGame();
      final topology = armyCorpusTopology();
      expectArmyMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: ArmyMoveOrder(
          armyId: 'field_a',
          destinationProvinceId: 'oldWorld|P2',
        ),
        label: 'own adjacent',
      );
    });

    test('army move: into other GP without war (rejected)', () {
      final game = armyCorpusGame();
      final topology = armyCorpusTopology();
      expectArmyMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: ArmyMoveOrder(
          armyId: 'field_a',
          destinationProvinceId: 'oldWorld|P3',
        ),
        label: 'GP no war',
      );
    });

    test('army move: into other GP with same-turn declare war (accepted)', () {
      final game = armyCorpusGame();
      final topology = armyCorpusTopology();
      final basePrefix = Orders(
        diplomaticOrdersByPlayerId: {
          'p1': [
            const DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'p2',
            ),
          ],
        },
      );
      expectArmyMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: basePrefix,
        candidate: ArmyMoveOrder(
          armyId: 'field_a',
          destinationProvinceId: 'oldWorld|P3',
        ),
        label: 'GP with declare war',
      );
    });

    test('army move: into Minor without war (rejected)', () {
      final game = armyCorpusGame();
      final topology = armyCorpusTopology();
      expectArmyMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: ArmyMoveOrder(
          armyId: 'field_a',
          destinationProvinceId: 'oldWorld|P4',
        ),
        label: 'minor no war',
      );
    });

    test('army move: missing army (rejected)', () {
      final game = armyCorpusGame();
      final topology = armyCorpusTopology();
      expectArmyMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: ArmyMoveOrder(
          armyId: 'unknown_army',
          destinationProvinceId: 'oldWorld|P2',
        ),
        label: 'unknown army',
      );
    });

    // ---- Naval move fixtures ----

    Game navalCorpusGame() {
      const ow = 'oldWorld';
      return Game(
        id: 'g_naval_eq',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|coastA', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|coastB', regionId: ow, ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'fleet_atSea',
              ownerId: 'p1',
              regionId: ow,
              seaZoneId: '$ow|sea1',
              shipTypeIds: const ['carrack'],
            ),
            Fleet(
              id: 'fleet_inPort',
              ownerId: 'p1',
              regionId: ow,
              inPortAtProvinceId: '$ow|coastA',
              shipTypeIds: const ['carrack'],
            ),
          ],
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|coastA': ['$ow|coastA|0|0'],
              '$ow|coastB': ['$ow|coastB|0|0'],
            },
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
    }

    MapTopology navalCorpusTopology() {
      const ow = 'oldWorld';
      return MapTopology(
        nodes: const [
          TopologyNode(id: '$ow|coastA', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: '$ow|coastB', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: '$ow|sea1', regionId: ow, type: TopologyNodeType.seaZone),
          TopologyNode(id: '$ow|sea2', regionId: ow, type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: '$ow|sea1', id2: '$ow|sea2'),
          TopologyEdge(id1: '$ow|sea1', id2: '$ow|coastA'),
          TopologyEdge(id1: '$ow|sea2', id2: '$ow|coastB'),
        ],
      );
    }

    test('naval move: at-sea fleet to adjacent sea zone (accepted)', () {
      final game = navalCorpusGame();
      final topology = navalCorpusTopology();
      expectNavalMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const NavalMoveOrder(
          fleetId: 'fleet_atSea',
          destinationSeaZoneId: 'oldWorld|sea2',
        ),
        label: 'sea1->sea2',
      );
    });

    test('naval move: at-sea fleet to non-adjacent sea zone (rejected)', () {
      final game = navalCorpusGame();
      final topology = navalCorpusTopology();
      expectNavalMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const NavalMoveOrder(
          fleetId: 'fleet_atSea',
          destinationSeaZoneId: 'oldWorld|seaZ',
        ),
        label: 'sea1->unknown',
      );
    });

    test('naval move: in-port fleet undock to adjacent sea zone (accepted)', () {
      final game = navalCorpusGame();
      final topology = navalCorpusTopology();
      expectNavalMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const NavalMoveOrder(
          fleetId: 'fleet_inPort',
          destinationSeaZoneId: 'oldWorld|sea1',
        ),
        label: 'inPort->sea1',
      );
    });

    test('naval move: missing fleet (rejected)', () {
      final game = navalCorpusGame();
      final topology = navalCorpusTopology();
      expectNavalMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const NavalMoveOrder(
          fleetId: 'unknown_fleet',
          destinationSeaZoneId: 'oldWorld|sea1',
        ),
        label: 'unknown fleet',
      );
    });

    // ---- Naval mission fixtures ----

    test('naval mission: patrol owned fleet (accepted)', () {
      final game = navalCorpusGame();
      final topology = navalCorpusTopology();
      expectNavalMissionEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const NavalMissionOrder(
          fleetId: 'fleet_atSea',
          mission: 'patrol',
        ),
        label: 'patrol owned',
      );
    });

    test('naval mission: blockade without target province (rejected)', () {
      final game = navalCorpusGame();
      final topology = navalCorpusTopology();
      expectNavalMissionEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const NavalMissionOrder(
          fleetId: 'fleet_atSea',
          mission: 'blockade',
        ),
        label: 'blockade no target',
      );
    });

    test('naval mission: missing fleet (rejected)', () {
      final game = navalCorpusGame();
      final topology = navalCorpusTopology();
      expectNavalMissionEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const NavalMissionOrder(
          fleetId: 'unknown_fleet',
          mission: 'patrol',
        ),
        label: 'unknown fleet',
      );
    });
  });
}
