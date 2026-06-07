import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/logic_validation_exception.dart';
import 'capital_reassignment_fatal.dart';
import 'player_state_pipeline.dart';
import 'province_lookup.dart';

export 'package:colonizethis_data/colonizethis_data.dart' show isProvinceSeaBound;

/// New capital **province** id for runtime reassignment after combat (not init capital choice).
/// [ownedProvinceIds] are full `regionId|localId`. Prefers **seaboard** provinces; if none, uses inland.
/// Deterministic: ascending sort by full id, first in the preferred set.
/// SPEC/game/capital-and-connectivity § Capital loss and reassignment.
String pickCapitalProvinceIdForReassignment(
  List<String> ownedProvinceIds,
  MapTopology topology,
) {
  if (ownedProvinceIds.isEmpty) {
    throw LogicValidationException(
      'capital_reassignment_requires_owned_provinces: ownedProvinceIds must be non-empty',
    );
  }
  final sorted = List<String>.from(ownedProvinceIds)..sort();
  final seaBound = sorted
      .where((id) => isProvinceSeaBound(topology, ProvinceId.localIdFrom(id)))
      .toList();
  if (seaBound.isNotEmpty) return seaBound.first;
  return sorted.first;
}

/// SPEC/game/capital-and-connectivity § Capital province town development (Great Powers).
/// [capitalProvinceId] may be full (`regionId|localId`) or local only; match by local id
/// within [regionId].
WorldState applyGreatPowerCapitalProvinceTownDevelopment(
  WorldState worldState,
  String regionId,
  String capitalProvinceId,
) {
  final localTarget = ProvinceId.isPrefixed(capitalProvinceId)
      ? ProvinceId.localIdFrom(capitalProvinceId)
      : capitalProvinceId;
  return worldState.updateRegionById(
    regionId,
    (region) => RegionData(
      provinces: region.provinces
          .map(
            (p) => ProvinceId.localIdFrom(p.id) == localTarget
                ? p.copyWith(townDevelopmentLevel: 4)
                : p,
          )
          .toList(),
      units: region.units,
    ),
  );
}

/// Sets [playerId]'s capital after runtime reassignment (combat). Updates **only** player
/// `capitalProvinceId` and `capitalTile`; does not place ports, roads, or change province
/// `townTileKey`. SPEC/game/capital-and-connectivity § Capital loss and reassignment.
Game setCapitalForReassignment({
  required Game game,
  required String playerId,
  required String provinceId,
  required CapitalTile tile,
}) {
  if (tile.provinceId != provinceId) {
    throw CapitalReassignmentFatalError(
      'Capital tile province ${tile.provinceId} does not match $provinceId',
    );
  }
  return game.mapPlayers((p) {
    if (p.id != playerId) return p;
    return p.copyWith(capitalProvinceId: provinceId, capitalTile: tile);
  });
}

/// Sets [minorId]'s capital after runtime reassignment (combat / debug flip).
Game setCapitalForMinorReassignment({
  required Game game,
  required String minorId,
  required String provinceId,
  required CapitalTile tile,
}) {
  if (tile.provinceId != provinceId) {
    throw CapitalReassignmentFatalError(
      'Capital tile province ${tile.provinceId} does not match $provinceId',
    );
  }
  final updatedMinors = game.minorNations
      .map(
        (m) => m.id != minorId
            ? m
            : m.copyWith(capitalProvinceId: provinceId, capitalTile: tile),
      )
      .toList();
  return game.copyWith(minorNations: updatedMinors);
}

/// Sets [tribeId]'s capital after runtime reassignment (combat / debug flip).
Game setCapitalForTribeReassignment({
  required Game game,
  required String tribeId,
  required String provinceId,
  required CapitalTile tile,
}) {
  if (tile.provinceId != provinceId) {
    throw CapitalReassignmentFatalError(
      'Capital tile province ${tile.provinceId} does not match $provinceId',
    );
  }
  final updatedTribes = game.tribes
      .map(
        (t) => t.id != tribeId
            ? t
            : t.copyWith(capitalProvinceId: provinceId, capitalTile: tile),
      )
      .toList();
  return game.copyWith(tribes: updatedTribes);
}
