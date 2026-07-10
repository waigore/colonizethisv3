import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared topology and army helpers for [MoveValidator] / [ArmyMoveValidator] tests.
MapTopology moveValidatorTestTwoProvinceTopology(String regionId) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: 'P1',
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'P2',
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
    ],
    edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
  );
}

Army moveValidatorTestFieldArmy(
  String regionId,
  String ownerId,
  String localId,
  String unitId,
) {
  final pid = ProvinceId.full(regionId, localId);
  return Army(
    id: fieldArmyIdFor(ownerId, pid),
    ownerId: ownerId,
    regionId: regionId,
    stationedProvinceId: pid,
    regimentUnitIds: [unitId],
    isHomeArmy: false,
  );
}

/// Builds the canonical [OrderResolutionContext] for [MoveValidator] tests
/// from a [game] + [topology] + [playerId] triple, mirroring the per-pass
/// snapshot the engine entry-point threads through validator probes
/// (Refs #2836 AC 3; SPEC/program/logic-validator-units-params.md).
///
/// Combines both old-world and new-world units into the same `unitsById`
/// map so tests that exercise dual-region fixtures get a context whose
/// unit lookup matches the engine's per-pass build.
OrderResolutionContext moveValidatorTestContext(
  Game game,
  MapTopology topology,
  String playerId,
) {
  final unitsById = <String, Unit>{
    for (final u in game.worldState.oldWorld.units) u.id: u,
    for (final u in game.worldState.newWorld.units) u.id: u,
  };
  final view = buildPlayerView(game, topology, playerId);
  return orderResolutionContextFromView(view, game, unitsById: unitsById);
}
