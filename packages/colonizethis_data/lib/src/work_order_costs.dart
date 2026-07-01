import 'package:colonizethis_models/colonizethis_models.dart';

import 'commodities.dart';

/// Work order material costs and durations. SPEC/game/civilian-units.md, extraction-and-improvements.md, siege-mechanics.md. Single source of truth for stockpile costs in order validation and application.
/// Durations: `totalTurnsForWork` below is authoritative for **assign-time** `currentWork.totalTurns` (standard material-backed targets, `prospect`, `purchase_land`; `explore` is overridden by province-scaled logic in colonizethis_logic). **When** treasury is debited and when prospection / `purchasedTilesByTileKey` update for `prospect` / `purchase_land` is specified in SPEC/program/orders.md (§ Civilian deferred primary effects) and SPEC/program/development-resolution.md — not in this file. See `applyBuildAndWorkOrders` in colonizethis_logic.

/// Material cost for a work order: commodity id -> quantity.
typedef WorkOrderCost = Map<String, int>;

/// Duration in turns for a work target. Used when assigning `currentWork` for standard development orders.
int totalTurnsForWork(String workTarget, {int? improvementLevel, int? fortLevel}) {
  switch (workTarget) {
    case 'explore':
      return 3; // Overridden by resolution from province size
    case 'prospect':
      return 1;
    case 'build_improvement':
      return 1; // Can scale by improvementLevel later
    case 'upgrade_town':
      return 1;
    case 'build_road':
      return 1;
    case 'build_port':
      return 1;
    case 'build_fort':
      return (fortLevel ?? 0) + 1;
    case 'build_rail':
      return 1;
    case 'counter_spy':
      return 0; // Ongoing, no completion
    case 'purchase_land':
      return 1;
    default:
      return 1;
  }
}

/// Material cost for build_improvement at given current level (cost to raise to level+1).
/// SPEC: level 1 = 1 lumber + 1 cast iron; 2 = 4+4; 3 = 8+8; 4 = 16+16.
WorkOrderCost workOrderCostBuildImprovement(int currentLevel) {
  final clampedLevel = currentLevel.clamp(0, 3);
  const scalesByNextLevel = [1, 4, 8, 16];
  final scale = scalesByNextLevel[clampedLevel];
  return {
    CommodityCatalog.lumber.id: scale,
    CommodityCatalog.castIron.id: scale,
  };
}

/// Material cost for build_road (transport level 1). SPEC: 1 lumber + 1 cast iron.
WorkOrderCost get workOrderCostBuildRoad => {
      CommodityCatalog.lumber.id: 1,
      CommodityCatalog.castIron.id: 1,
    };

/// Material cost for build_port. SPEC: lumber + metal (same as road).
WorkOrderCost get workOrderCostBuildPort => {
      CommodityCatalog.lumber.id: 1,
      CommodityCatalog.castIron.id: 1,
    };

/// Material cost for build_fort at given level. SPEC siege-mechanics: 1=3 Lumber+3 Bronze, 2=4+4, 3=5 Steel+5 Lumber.
WorkOrderCost workOrderCostBuildFort(int currentFortLevel) {
  switch (currentFortLevel) {
    case 0:
      return {
        CommodityCatalog.lumber.id: 3,
        CommodityCatalog.bronze.id: 3,
      };
    case 1:
      return {
        CommodityCatalog.lumber.id: 4,
        CommodityCatalog.bronze.id: 4,
      };
    case 2:
      return {
        CommodityCatalog.steel.id: 5,
        CommodityCatalog.lumber.id: 5,
      };
    default:
      return {};
  }
}

/// Material cost for build_rail. SPEC: 2 lumber + 2 steel per tile.
WorkOrderCost get workOrderCostBuildRail => {
      CommodityCatalog.lumber.id: 2,
      CommodityCatalog.steel.id: 2,
    };

/// Material cost for upgrade_town. Per ruleset; use level-1 improvement cost as default.
WorkOrderCost get workOrderCostUpgradeTown => workOrderCostBuildImprovement(0);

/// Returns material cost for a work order, or null if no material cost (e.g. explore, prospect, steal_tech, counter_spy, purchase_land uses treasury).
WorkOrderCost? workOrderMaterialCost(
  String workTarget, {
  int? improvementLevel,
  int? fortLevel,
  int? roadLevel,
}) {
  switch (workTarget) {
    case 'explore':
    case 'prospect':
    case 'counter_spy':
    case 'purchase_land':
      return null;
    case 'build_improvement':
      return workOrderCostBuildImprovement(improvementLevel ?? 0);
    case 'upgrade_town':
      return workOrderCostUpgradeTown;
    case 'build_road':
      return workOrderCostBuildRoad;
    case 'build_port':
      return workOrderCostBuildPort;
    case 'build_fort':
      return workOrderCostBuildFort(fortLevel ?? 0);
    case 'build_rail':
      return workOrderCostBuildRail;
    default:
      return null;
  }
}

/// Allowed work order targets per unit type. SPEC/game/civilian-units.md Work Order Summary.
const Map<String, List<String>> workOrderTargetsByUnitType = {
  kUnitTypeExplorer: ['explore', 'prospect'],
  kUnitTypeBuilder: ['build_improvement', 'upgrade_town'],
  kUnitTypeEngineer: ['build_road', 'build_port', 'build_fort'],
  kUnitTypeRailBuilder: ['build_rail'],
  kUnitTypeSpy: ['counter_spy'],
  kUnitTypeMerchant: ['purchase_land'],
};

/// Returns true if [unitType] can perform work order [target].
bool isWorkOrderTargetAllowedForUnitType(String unitType, String target) {
  final allowed = workOrderTargetsByUnitType[unitType];
  return allowed != null && allowed.contains(target);
}
