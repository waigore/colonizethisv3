import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/movement.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Exercises land-move adjacency validation and civilian tile-move application
/// in `lib/src/world/movement.dart`. SPEC/program/movement.md and
/// SPEC/game/world-model-identity.md.
const String _civ = kUnitTypeBuilder;

Unit _civilian(
  String id, {
  String ownerId = 'p1',
  required String tileKey,
}) {
  final province = Unit.provinceIdFromTileKey(tileKey)!;
  return Unit(
    id: id,
    type: _civ,
    ownerId: ownerId,
    locationProvinceId: province,
    tileKey: tileKey,
  );
}

Game _gameWithUnits({
  List<Unit> oldWorldUnits = const [],
  List<Unit> newWorldUnits = const [],
}) => TestFixtures.minimalGame(
  players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  oldWorld: RegionData(units: oldWorldUnits),
  newWorld: RegionData(units: newWorldUnits),
);

/// Local-id topology (`p1`–`p2`) for [isValidLandMove], which keys on node ids.
MapTopology _localTopology() => const MapTopology(
  nodes: [
    TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'p3', regionId: 'oldWorld', type: TopologyNodeType.province),
  ],
  edges: [TopologyEdge(id1: 'p1', id2: 'p2')],
);

void main() {
  group('neighborProvinceIdsInRegion / isValidLandMoveInRegion', () {
    final topology = _localTopology();

    test('returns adjacent local ids within the region', () {
      final neighbors = neighborProvinceIdsInRegion(
        topology,
        'oldWorld',
        'p1',
      ).toList();
      expect(neighbors, ['p2']);
    });

    test('returns nothing for a province not in the region', () {
      expect(
        neighborProvinceIdsInRegion(topology, 'oldWorld', 'unknown'),
        isEmpty,
      );
    });

    test('valid neighbor move is accepted, non-neighbor rejected', () {
      expect(isValidLandMoveInRegion(topology, 'oldWorld', 'p1', 'p2'), isTrue);
      expect(isValidLandMoveInRegion(topology, 'oldWorld', 'p1', 'p3'), isFalse);
    });

    test('a move onto the same province is invalid', () {
      expect(isValidLandMoveInRegion(topology, 'oldWorld', 'p1', 'p1'), isFalse);
    });
  });

  group('isValidLandMove', () {
    final topology = _localTopology();

    test('accepts adjacent provinces resolved through a single node', () {
      expect(isValidLandMove(topology, 'p1', 'p2'), isTrue);
    });

    test('rejects identical from/to', () {
      expect(isValidLandMove(topology, 'p1', 'p1'), isFalse);
    });

    test('rejects when the from-province has no resolvable node', () {
      expect(isValidLandMove(topology, 'ghost', 'p2'), isFalse);
    });
  });

  group('applyCivilianTileMoveOrdersToWorldRegions', () {
    test('returns unchanged regions for empty orders', () {
      final game = _gameWithUnits(
        oldWorldUnits: [_civilian('u1', tileKey: 'oldWorld|p1|0|0')],
      );
      final result = applyCivilianTileMoveOrdersToWorldRegions(game, const {});
      expect(result.oldWorld, same(game.worldState.oldWorld));
      expect(result.newWorld, same(game.worldState.newWorld));
    });

    test('moves a civilian within the same region', () {
      final game = _gameWithUnits(
        oldWorldUnits: [_civilian('u1', tileKey: 'oldWorld|p1|0|0')],
      );
      final result = applyCivilianTileMoveOrdersToWorldRegions(game, const {
        'p1': [MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p2|1|1')],
      });
      final moved = result.oldWorld.units.firstWhere((u) => u.id == 'u1');
      expect(moved.locationProvinceId, 'oldWorld|p2');
      expect(moved.tileKey, 'oldWorld|p2|1|1');
    });

    test('moves a civilian across regions', () {
      final game = _gameWithUnits(
        oldWorldUnits: [_civilian('u1', tileKey: 'oldWorld|p1|0|0')],
      );
      final result = applyCivilianTileMoveOrdersToWorldRegions(game, const {
        'p1': [MoveOrder(unitId: 'u1', destinationTileKey: 'newWorld|n1|2|2')],
      });
      expect(result.oldWorld.units.any((u) => u.id == 'u1'), isFalse);
      final moved = result.newWorld.units.firstWhere((u) => u.id == 'u1');
      expect(moved.locationProvinceId, 'newWorld|n1');
    });

    test('ignores unknown unit, owner mismatch, and military units', () {
      final game = _gameWithUnits(
        oldWorldUnits: [
          _civilian('owned', tileKey: 'oldWorld|p1|0|0'),
          _civilian('other', ownerId: 'p2', tileKey: 'oldWorld|p1|0|0'),
          Unit(
            id: 'soldier',
            type: 'grenadiers',
            ownerId: 'p1',
            locationProvinceId: 'oldWorld|p1',
          ),
        ],
      );
      final reasons = <String?>[];
      applyCivilianTileMoveOrdersToWorldRegions(
        game,
        const {
          'p1': [
            MoveOrder(unitId: 'missing', destinationTileKey: 'oldWorld|p2|0|0'),
            MoveOrder(unitId: 'other', destinationTileKey: 'oldWorld|p2|0|0'),
            MoveOrder(unitId: 'soldier', destinationTileKey: 'oldWorld|p2|0|0'),
          ],
        },
        onCivilianMoveOrderTrace:
            ({required playerId, required order, required applied, ignoreReason}) =>
                reasons.add(ignoreReason),
      );
      expect(reasons, ['unit_not_found', 'owner_mismatch', 'military_unit']);
    });

    test('traces invalid_destination for a malformed tile key', () {
      final game = _gameWithUnits(
        oldWorldUnits: [_civilian('u1', tileKey: 'oldWorld|p1|0|0')],
      );
      final reasons = <String?>[];
      applyCivilianTileMoveOrdersToWorldRegions(
        game,
        const {
          'p1': [MoveOrder(unitId: 'u1', destinationTileKey: 'badkey')],
        },
        onCivilianMoveOrderTrace:
            ({required playerId, required order, required applied, ignoreReason}) =>
                reasons.add(ignoreReason),
      );
      expect(reasons, ['invalid_destination']);
    });
  });

  group('applyMoveOrdersToRegion (legacy no-op)', () {
    test('returns the region data unchanged', () {
      const region = RegionData(
        provinces: [Province(id: 'oldWorld|p1', regionId: 'oldWorld')],
      );
      final result = applyMoveOrdersToRegion(
        region,
        const MapTopology(),
        const {
          'p1': [MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p2|0|0')],
        },
        regionId: 'oldWorld',
      );
      expect(result, same(region));
    });
  });
}
