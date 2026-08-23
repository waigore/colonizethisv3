import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/army_movement.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';
import 'army_movement_apply_cases.dart';

/// Army move application pins (Refs #3290 / densify #4330 Slice C).
/// SPEC/game/military-armies.md and SPEC/program/movement.md.
void main() {
  group('armiesByIdForWorld', () {
    test('indexes armies by id', () {
      final world = armyMoveWorld(armies: [testArmy('a1'), testArmy('a2')]);
      final byId = armiesByIdForWorld(world);
      expect(byId.keys, containsAll(['a1', 'a2']));
      expect(byId['a1']!.id, 'a1');
    });
  });

  group('applyArmyMoveOrdersToRegion', () {
    final topology = prefixedAdjacentProvincesTopology(regionId: 'oldWorld');

    test('returns same world when there are no orders', () {
      final world = armyMoveWorld(armies: [testArmy('a1')]);
      expect(
        applyArmyMoveOrdersToRegion(
          world,
          topology,
          const {},
          regionId: 'oldWorld',
        ),
        same(world),
      );
    });

    test('ignores unknown army, owner mismatch, and home army', () {
      final world = armyMoveWorld(
        armies: [
          testArmy('home', isHomeArmy: true),
          testArmy('other', ownerId: 'p2'),
        ],
      );
      final next = applyArmyMoveOrdersToRegion(world, topology, const {
        'p1': [
          ArmyMoveOrder(
            armyId: 'missing',
            destinationProvinceId: 'oldWorld|p2',
          ),
          ArmyMoveOrder(armyId: 'other', destinationProvinceId: 'oldWorld|p2'),
          ArmyMoveOrder(armyId: 'home', destinationProvinceId: 'oldWorld|p2'),
        ],
      }, regionId: 'oldWorld');
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
      final world = armyMoveWorld(
        armies: [
          testArmy(
            'a1',
            stationedProvinceId: 'newWorld|n1',
            regionId: 'newWorld',
          ),
        ],
      );
      final next = applyArmyMoveOrdersToRegion(world, topology, const {
        'p1': [
          ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'oldWorld|p2'),
        ],
      }, regionId: 'oldWorld');
      expect(next.armies.single.stationedProvinceId, 'newWorld|n1');
    });

    for (final case_ in _regionIgnoreTraceCases) {
      test(case_.description, () {
        final world = armyMoveWorld(armies: [testArmy('a1')]);
        final traces = collectArmyMoveIgnoreReasons(world, topology, {
          'p1': [
            ArmyMoveOrder(
              armyId: 'a1',
              destinationProvinceId: case_.destination,
            ),
          ],
        }, regionId: 'oldWorld');
        expect(traces, [case_.ignoreReason]);
        expect(world.armies.single.stationedProvinceId, 'oldWorld|p1');
      });
    }

    test('applies a valid adjacent move and traces applied', () {
      final world = armyMoveWorld(armies: [testArmy('a1')]);
      final traces = collectArmyMoveIgnoreReasons(world, topology, const {
        'p1': [ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'p2')],
      }, regionId: 'oldWorld');
      expect(traces, ['applied']);
      final next = applyArmyMoveOrdersToRegion(world, topology, const {
        'p1': [ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'p2')],
      }, regionId: 'oldWorld');
      expect(next.armies.single.stationedProvinceId, 'oldWorld|p2');
    });

    test('owned-destination override bypasses adjacency check', () {
      final world = armyMoveWorld(armies: [testArmy('a1')]);
      final next = applyArmyMoveOrdersToRegion(
        world,
        topology,
        const {
          'p1': [
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'oldWorld|p3'),
          ],
        },
        regionId: 'oldWorld',
        isDestinationOwnedByPlayer: (playerId, dest) => dest == 'oldWorld|p3',
      );
      expect(next.armies.single.stationedProvinceId, 'oldWorld|p3');
    });
  });

  registerArmyMovementApplyCases();
}

typedef _IgnoreTraceCase = ({
  String description,
  String destination,
  String ignoreReason,
});

const List<_IgnoreTraceCase> _regionIgnoreTraceCases = [
  (
    description:
        'traces destination_in_other_region for cross-region prefixed dest',
    destination: 'newWorld|n1',
    ignoreReason: 'destination_in_other_region',
  ),
  (
    description: 'traces invalid_adjacency when destination is not a neighbor',
    destination: 'oldWorld|p3',
    ignoreReason: 'invalid_adjacency',
  ),
];
