/// Neutral military counsel scoring helpers. SPEC/program/military-counsel-ranking.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'military_counsel_types.dart';

double militaryCounselScoreBuildUnit(String unitType) {
  final regiment = RegimentEconomyCatalog.byId[unitType];
  if (regiment != null) {
    final cost = regiment.buildTreasuryCost;
    if (cost <= 0) return 0;
    return 1000.0 / cost;
  }
  final ship = ShipEconomyCatalog.byId[unitType];
  if (ship != null) {
    final cargoHold = NavalStatsCatalog.get(unitType).cargoHold;
    return 1.0 + cargoHold * 0.1;
  }
  return 0;
}

MilitaryCounselReasonKey militaryCounselReasonForInvade({
  required Game game,
  required String playerId,
  required String ownerFactionId,
  required bool requiresDeclareWar,
}) {
  if (requiresDeclareWar) {
    return MilitaryCounselReasonKey.declareWarInvasion;
  }
  final rel = getRelation(game, playerId, ownerFactionId);
  if (rel != null && rel.atWar) {
    return MilitaryCounselReasonKey.atWarInvasion;
  }
  return MilitaryCounselReasonKey.declareWarInvasion;
}

double militaryCounselScoreInvade({
  required Game game,
  required String playerId,
  required String ownerFactionId,
}) {
  if (ownerFactionId.isEmpty || ownerFactionId == playerId) {
    return 0;
  }
  final rel = getRelation(game, playerId, ownerFactionId);
  final atWar = rel != null && rel.atWar;
  return 1.0 + (atWar ? kMovePreferEnemyTerritoryBonus.toDouble() : 0);
}

MilitaryCounselBuildCostSnapshot militaryCounselBuildCostSnapshotFor(
  String unitType,
) {
  final category = buildUnitCategoryForUnitType(unitType);
  switch (category) {
    case BuildUnitCategory.military:
      final econ = RegimentEconomyCatalog.byId[unitType]!;
      return MilitaryCounselBuildCostSnapshot(
        treasuryCost: econ.buildTreasuryCost,
        materialCosts: Map<CommodityId, int>.from(econ.buildInputs),
        peasantCost: 1,
      );
    case BuildUnitCategory.naval:
      final econ = ShipEconomyCatalog.byId[unitType]!;
      return MilitaryCounselBuildCostSnapshot(
        treasuryCost: econ.buildTreasuryCost,
        materialCosts: Map<CommodityId, int>.from(econ.buildInputs),
        peasantCost: 1,
      );
    case BuildUnitCategory.civilian:
    case BuildUnitCategory.unknown:
      return const MilitaryCounselBuildCostSnapshot(
        treasuryCost: 0,
        materialCosts: {},
        peasantCost: 0,
      );
  }
}
