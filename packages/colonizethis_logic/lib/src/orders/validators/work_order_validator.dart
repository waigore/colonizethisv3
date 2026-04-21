import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../../diplomacy/diplomacy_resolver.dart';
import '../../world/civilian_tile_occupancy.dart';
import '../../world/player_view.dart';
import '../../world/province_lookup.dart';
import '../../world/tile_control.dart';
import '../build_rail_work_rules.dart';
import '../orders_application_helpers.dart';
import '../order_visibility.dart';
import '../order_validation_result.dart';
import '../unit_type_helpers.dart';
import 'work_order_cost_calculator.dart';
import 'work_order_target_prechecks.dart';

/// Validates work orders for a single player in submission order.
/// Mutates internal economy state (stockpile, treasury) and [devExclusiveTiles]
/// when an order is accepted. SPEC/program/orders.md § Work orders.
class WorkOrderValidationContext {
  const WorkOrderValidationContext({
    required this.game,
    required this.player,
    required this.playerId,
    required this.view,
    required this.unitsById,
    required this.devExclusiveTiles,
    this.tileMapByRegion,
  });

  final Game game;
  final Player player;
  final String playerId;
  final PlayerView view;
  final Map<String, Unit> unitsById;
  final Set<String> devExclusiveTiles;
  final Map<String, TileMapResult>? tileMapByRegion;
}

class WorkOrderValidator extends OrderValidator {
  final WorkOrderValidationContext _context;

  Stockpile _stockpile;
  int _treasury;
  final Set<String> _seenUnitIds;

  WorkOrderValidator({
    required WorkOrderValidationContext context,
    required Stockpile stockpile,
    required int treasury,
    Set<String> initialSeenUnitIds = const <String>{},
  }) : _context = context,
       _stockpile = stockpile,
       _treasury = treasury,
       _seenUnitIds = {...initialSeenUnitIds};

  Stockpile get stockpile => _stockpile;
  int get treasury => _treasury;

  /// Validates one [WorkOrder]. When accepted, deducts cost from internal
  /// stockpile/treasury and may add to [devExclusiveTiles]. Caller should sync
  /// stockpile/treasury back after the work loop.
  OrderValidationResult validate(
    WorkOrder o, {
    required bool previousRejected,
  }) {
    return shortCircuitIfPreviousRejected(
      previousRejected: previousRejected,
      body: () {
        final unit = _context.unitsById[o.unitId];
        if (unit == null || unit.ownerId != _context.playerId) {
          return OrderValidationResult.rejected('Unit not found');
        }
        if (_seenUnitIds.contains(o.unitId)) {
          return OrderValidationResult.rejected(
            'Only one work order per unit is allowed each turn',
          );
        }
        _seenUnitIds.add(o.unitId);
        if (unit.currentWork != null) {
          return OrderValidationResult.rejected(
            'Unit already has a work order; cancel first',
          );
        }
        final type = unit.type;
        if (!isWorkOrderTargetAllowedForUnitType(type, o.target)) {
          return OrderValidationResult.rejected(
            'Invalid work target for unit type',
          );
        }
        if (o.targetTileKey.isEmpty) {
          return OrderValidationResult.rejected(
            'Work order requires a target tile',
          );
        }

        final targetProvinceId = Unit.provinceIdFromTileKey(o.targetTileKey);
        final province = targetProvinceId != null
            ? _context.game.worldState.tryGetProvince(targetProvinceId)
            : null;
        final ownerId = province?.ownerId;

        final preCtx = WorkOrderTargetPrecheckContext(
          game: _context.game,
          player: _context.player,
          playerId: _context.playerId,
          treasury: _treasury,
          civilianEmbassyWorkAllowed: _civilianWorkAllowedInMinorTribeProvince,
        );
        final preResult = runWorkOrderTargetPrecheck(
          preCtx,
          o,
          targetProvinceId,
          ownerId,
          type,
        );
        if (preResult != null) {
          return preResult;
        }

        if (!isExplorerUnit(type) &&
            !kWorkTargetsSkippingDefaultForeignProvinceCheck.contains(
              o.target,
            )) {
          final controlled = isTileControlledByPlayer(
            _context.game,
            _context.playerId,
            o.targetTileKey,
          );
          final embassyWork = _civilianWorkAllowedInMinorTribeProvince(
            type,
            ownerId,
          );
          if (!controlled && !embassyWork) {
            return OrderValidationResult.rejected(
              'Cannot work in foreign province',
            );
          }
        }

        if (isDevExclusiveUnitType(type) &&
            isDevExclusiveWorkTarget(o.target) &&
            _context.devExclusiveTiles.contains(o.targetTileKey)) {
          return OrderValidationResult.rejected(
            'Tile already has development or purchase work for this player',
          );
        }

        final materialRuleResult = _validateMaterialAndTechRules(
          o,
          province?.fortLevel ?? 0,
        );
        if (materialRuleResult != null) return materialRuleResult;

        if (!workOrderVisibilityOk(
          _context.view,
          unit,
          o.target,
          o.targetTileKey,
        )) {
          return OrderValidationResult.rejected(
            'Province or tile not visible for this work',
          );
        }

        if (!civilianMayOccupyLandTileKey(
          game: _context.game,
          playerId: _context.playerId,
          unitType: type,
          destinationTileKey: o.targetTileKey,
        )) {
          return OrderValidationResult.rejected(
            'Unit cannot occupy target tile',
          );
        }

        final prospectResult = _validateProspectTarget(o);
        if (prospectResult != null) return prospectResult;

        if (isDevExclusiveUnitType(type) &&
            isDevExclusiveWorkTarget(o.target)) {
          _context.devExclusiveTiles.add(o.targetTileKey);
        }

        _applyProjectedWorkCost(o);

        return OrderValidationResult.accepted();
      },
    );
  }

  OrderValidationResult? _validateMaterialAndTechRules(
    WorkOrder o,
    int fortLevel,
  ) {
    if (o.target == kWorkTargetStealTech ||
        o.target == kWorkTargetCounterSpy ||
        o.target == kWorkTargetPurchaseLand) {
      return null;
    }
    final improvementLevel = _improvementLevelForCost(o);
    final roadLevel = _context.game.worldState.tileState.roadLevel(
      o.targetTileKey,
    );
    final techResult = _validateRoadFortRailTech(o, fortLevel, roadLevel);
    if (techResult != null) return techResult;
    return _validateWorkMaterialCosts(
      o,
      improvementLevel: improvementLevel,
      fortLevel: fortLevel,
      roadLevel: roadLevel,
    );
  }

  int _improvementLevelForCost(WorkOrder o) =>
      o.target == kWorkTargetBuildImprovement
      ? _context.game.worldState.tileState.improvementLevel(o.targetTileKey)
      : 0;

  OrderValidationResult? _validateRoadFortRailTech(
    WorkOrder o,
    int fortLevel,
    int roadLevel,
  ) {
    if (o.target == kWorkTargetBuildRoad && roadLevel >= 1) {
      final hasRoadConstruction =
          _context.player.techUnlocked?[kTechIdRoadConstruction] == true;
      if (!hasRoadConstruction) {
        return OrderValidationResult.rejected(
          'Road Construction tech required for transport level 2',
        );
      }
    }
    if (o.target == kWorkTargetBuildFort) {
      if (fortLevel == 1 &&
          _context.player.techUnlocked?[kTechIdMineEngineering] != true) {
        return OrderValidationResult.rejected(
          'Mine Engineering tech required for fort level 2',
        );
      }
      if (fortLevel == 2 &&
          _context.player.techUnlocked?[kTechIdModernForts] != true) {
        return OrderValidationResult.rejected(
          'Modern Forts tech required for fort level 3',
        );
      }
    }
    if (o.target == kWorkTargetBuildRail) {
      final terrain = terrainTypeForTileKey(
        _context.tileMapByRegion,
        o.targetTileKey,
      );
      final reason = rejectionReasonForBuildRailOrder(
        techUnlocked: _context.player.techUnlocked,
        roadLevel: roadLevel,
        terrain: terrain,
      );
      if (reason != null) return OrderValidationResult.rejected(reason);
    }
    return null;
  }

  OrderValidationResult? _validateWorkMaterialCosts(
    WorkOrder o, {
    required int improvementLevel,
    required int fortLevel,
    required int roadLevel,
  }) {
    final costMap = WorkOrderCostCalculator(_context.game).calculateCost(
      o.target,
      o.targetTileKey,
      improvementLevel: improvementLevel,
      fortLevel: fortLevel,
      roadLevel: roadLevel,
    );
    if (costMap == null) return null;
    for (final entry in costMap.entries) {
      if (_stockpile.quantityOf(entry.key) < entry.value) {
        return OrderValidationResult.rejected(
          'Insufficient materials for work order',
        );
      }
    }
    return null;
  }

  OrderValidationResult? _validateProspectTarget(WorkOrder o) {
    if (o.target != kWorkTargetProspect) return null;
    if (!isMineralEligibleTile(
      _context.game,
      _context.tileMapByRegion,
      o.targetTileKey,
    )) {
      return OrderValidationResult.rejected(
        'Tile is not mineral-eligible for prospecting',
      );
    }
    final prospected =
        _context.game.worldState.playerProspectedTiles[_context.playerId] ??
        const <String>{};
    if (prospected.contains(o.targetTileKey)) {
      return OrderValidationResult.rejected('Tile already prospected');
    }
    return null;
  }

  void _applyProjectedWorkCost(WorkOrder o) {
    if (o.target == kWorkTargetPurchaseLand) {
      final resourceId =
          _context.game.worldState.resourceByTileKey[o.targetTileKey];
      if (resourceId != null && resourceId.isNotEmpty) {
        _treasury -= purchaseLandCost(resourceId);
      }
      return;
    }
    if (o.target == kWorkTargetStealTech || o.target == kWorkTargetCounterSpy) {
      return;
    }
    final costMap = WorkOrderCostCalculator(_context.game).calculateCost(
      o.target,
      o.targetTileKey,
      improvementLevel: _improvementLevelForCost(o),
    );
    if (costMap == null) return;
    for (final entry in costMap.entries) {
      if (_stockpile.quantityOf(entry.key) >= entry.value) {
        _stockpile = _stockpile.applyDelta(entry.key, -entry.value);
      }
    }
  }

  /// Builder / Engineer / Merchant may work in Minor/Tribe provinces with embassy + Diplomatic Expertise. SPEC/game/tech-tree-diplomacy-civilian.md.
  bool _civilianWorkAllowedInMinorTribeProvince(
    String unitType,
    String? provinceOwnerId,
  ) {
    if (provinceOwnerId == null || provinceOwnerId == _context.playerId) {
      return false;
    }
    if (unitType != kUnitTypeBuilder &&
        unitType != kUnitTypeEngineer &&
        unitType != kUnitTypeMerchant) {
      return false;
    }
    if (!isMinorOrTribe(_context.game, provinceOwnerId)) return false;
    final rel = getRelation(_context.game, _context.playerId, provinceOwnerId);
    if (rel?.atWar == true) return false;
    final overture = getOverture(
      _context.game,
      _context.playerId,
      provinceOwnerId,
    );
    if (overture == null || !overture.hasEmbassy) return false;
    return _context.player.techUnlocked?[kTechIdDiplomaticExpertise] == true;
  }
}
