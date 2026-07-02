import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/army_movement.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Exercises same-region and cross-region army move application in
/// `lib/src/world/army_movement.dart`. SPEC/game/military-armies.md and
/// SPEC/program/movement.md.
Army _army(
  String id, {
  String ownerId = 'p1',
  String stationedProvinceId = 'oldWorld|p1',
  String regionId = 'oldWorld',
  List<String> regimentUnitIds = const [],
  bool isHomeArmy = false,
}) => Army(
  id: id,
  ownerId: ownerId,
  regionId: regionId,
  stationedProvinceId: stationedProvinceId,
  regimentUnitIds: regimentUnitIds,
  isHomeArmy: isHomeArmy,
);

WorldState _worldWith({
  List<Army> armies = const [],
  List<Province> oldWorld = const [],
  List<Province> newWorld = const [],
}) => TestFixtures.worldStateAtOrdersPhase(
  oldWorld: RegionData(provinces: oldWorld),
  newWorld: RegionData(provinces: newWorld),
  armies: armies,
);

/// Two adjacent provinces `oldWorld|p1`–`oldWorld|p2` in a single-region topology.
MapTopology _adjacentOldWorldTopology() => const MapTopology(
  nodes: [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|p2',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|p3',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2')],
);

void main() {
  group('armiesByIdForWorld', () {
    test('indexes armies by id', () {
      final world = _worldWith(armies: [_army('a1'), _army('a2')]);
      final byId = armiesByIdForWorld(world);
      expect(byId.keys, containsAll(['a1', 'a2']));
      expect(byId['a1']!.id, 'a1');
    });
  });

  group('applyArmyMoveOrdersToRegion', () {
    final topology = _adjacentOldWorldTopology();

    test('returns same world when there are no orders', () {
      final world = _worldWith(armies: [_army('a1')]);
      final next = applyArmyMoveOrdersToRegion(
        world,
        topology,
        const {},
        regionId: 'oldWorld',
      );
      expect(next, same(world));
    });

    test('ignores unknown army, owner mismatch, and home army', () {
      final world = _worldWith(
        armies: [
          _army('home', isHomeArmy: true),
          _army('other', ownerId: 'p2'),
        ],
      );
      final next = applyArmyMoveOrdersToRegion(
        world,
        topology,
        const {
          'p1': [
            ArmyMoveOrder(armyId: 'missing', destinationProvinceId: 'oldWorld|p2'),
            ArmyMoveOrder(armyId: 'other', destinationProvinceId: 'oldWorld|p2'),
            ArmyMoveOrder(armyId: 'home', destinationProvinceId: 'oldWorld|p2'),
          ],
        },
        regionId: 'oldWorld',
      );
      // None applied: stations unchanged.
      expect(
        next.armies.firstWhere((a) => a.id == 'other').stationedProvinceId,
        'oldWorld|p1',
      );
      expect(
        next.armies.firstWhere((a) => a.id == 'home').stationedProvinceId,
        'oldWorld|p1',
      );
    });

    test('ignores army stationed in a different region', () {
      final world = _worldWith(
        armies: [
          _army(
            'a1',
            stationedProvinceId: 'newWorld|n1',
            regionId: 'newWorld',
          ),
        ],
      );
      final next = applyArmyMoveOrdersToRegion(
        world,
        topology,
        const {
          'p1': [
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'oldWorld|p2'),
          ],
        },
        regionId: 'oldWorld',
      );
      expect(next.armies.single.stationedProvinceId, 'newWorld|n1');
    });

    test('traces destination_in_other_region for cross-region prefixed dest', () {
      final world = _worldWith(armies: [_army('a1')]);
      final traces = <String>[];
      final next = applyArmyMoveOrdersToRegion(
        world,
        topology,
        const {
          'p1': [
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'newWorld|n1'),
          ],
        },
        regionId: 'oldWorld',
        onArmyMoveOrderTrace:
            ({
              required playerId,
              required order,
              required applied,
              regionId,
              destinationProvinceId,
              ignoreReason,
            }) => traces.add(ignoreReason ?? 'applied'),
      );
      expect(traces, ['destination_in_other_region']);
      expect(next.armies.single.stationedProvinceId, 'oldWorld|p1');
    });

    test('traces invalid_adjacency when destination is not a neighbor', () {
      final world = _worldWith(armies: [_army('a1')]);
      final traces = <String?>[];
      final next = applyArmyMoveOrdersToRegion(
        world,
        topology,
        const {
          'p1': [
            // p1 -> p3 has no edge in the topology.
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'oldWorld|p3'),
          ],
        },
        regionId: 'oldWorld',
        onArmyMoveOrderTrace:
            ({
              required playerId,
              required order,
              required applied,
              regionId,
              destinationProvinceId,
              ignoreReason,
            }) => traces.add(ignoreReason),
      );
      expect(traces, ['invalid_adjacency']);
      expect(next.armies.single.stationedProvinceId, 'oldWorld|p1');
    });

    test('applies a valid adjacent move and traces applied', () {
      final world = _worldWith(armies: [_army('a1')]);
      var appliedSeen = false;
      final next = applyArmyMoveOrdersToRegion(
        world,
        topology,
        // Unprefixed local destination should resolve within the region.
        const {
          'p1': [ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'p2')],
        },
        regionId: 'oldWorld',
        onArmyMoveOrderTrace:
            ({
              required playerId,
              required order,
              required applied,
              regionId,
              destinationProvinceId,
              ignoreReason,
            }) {
              if (applied) appliedSeen = true;
            },
      );
      expect(appliedSeen, isTrue);
      expect(next.armies.single.stationedProvinceId, 'oldWorld|p2');
    });

    test('owned-destination override bypasses adjacency check', () {
      final world = _worldWith(armies: [_army('a1')]);
      final next = applyArmyMoveOrdersToRegion(
        world,
        topology,
        const {
          'p1': [
            // p1 -> p3 is not adjacent, but owned override allows it.
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'oldWorld|p3'),
          ],
        },
        regionId: 'oldWorld',
        isDestinationOwnedByPlayer: (playerId, dest) => dest == 'oldWorld|p3',
      );
      expect(next.armies.single.stationedProvinceId, 'oldWorld|p3');
    });
  });

  group('applyCrossRegionArmyMovesWithinOwnedProvinces', () {
    test('moves army instantly to an owned province in another region', () {
      final world = _worldWith(
        armies: [_army('a1')],
        newWorld: [
          const Province(
            id: 'newWorld|n1',
            regionId: 'newWorld',
            ownerId: 'p1',
          ),
        ],
      );
      final game = TestFixtures.singlePlayerGame(
        const Player(id: 'p1', displayName: 'P1', isHuman: true),
        gameId: 'g',
        worldState: world,
      );
      final result = applyCrossRegionArmyMovesWithinOwnedProvinces(
        game: game,
        worldState: world,
        armyMoveOrdersByPlayerId: const {
          'p1': [
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'newWorld|n1'),
          ],
        },
      );
      expect(
        result.worldState.armies.single.stationedProvinceId,
        'newWorld|n1',
      );
      expect(result.worldState.armies.single.regionId, 'newWorld');
      // Applied order is consumed (not returned as remaining).
      expect(result.remainingArmyMoveOrdersByPlayerId, isEmpty);
    });

    test('leaves same-region or unowned-destination orders as remaining', () {
      final world = _worldWith(
        armies: [_army('a1'), _army('home', isHomeArmy: true)],
        oldWorld: [
          const Province(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            ownerId: 'p1',
          ),
        ],
        newWorld: [
          const Province(
            id: 'newWorld|n1',
            regionId: 'newWorld',
            ownerId: 'p2',
          ),
        ],
      );
      final game = TestFixtures.singlePlayerGame(
        const Player(id: 'p1', displayName: 'P1', isHuman: true),
        gameId: 'g',
        worldState: world,
      );
      final result = applyCrossRegionArmyMovesWithinOwnedProvinces(
        game: game,
        worldState: world,
        armyMoveOrdersByPlayerId: const {
          'p1': [
            // Same region: not a cross-region move.
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'oldWorld|p2'),
            // Home army: skipped.
            ArmyMoveOrder(armyId: 'home', destinationProvinceId: 'newWorld|n1'),
            // Destination owned by another player: skipped.
            ArmyMoveOrder(
              armyId: 'a1',
              destinationProvinceId: 'newWorld|n1',
            ),
          ],
        },
      );
      expect(result.remainingArmyMoveOrdersByPlayerId['p1'], hasLength(3));
      expect(result.worldState.armies, world.armies);
    });
  });
}
