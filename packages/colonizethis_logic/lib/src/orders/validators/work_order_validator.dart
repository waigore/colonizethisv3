import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import 'package:colonizethis_economy/src/economy/projected_cost_engine.dart';
import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_resolver.dart';
import 'package:colonizethis_world/src/world/civilian_tile_occupancy.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/tile_control.dart';
import '../build_rail_work_rules.dart';
import '../bundled_civilian_work_order.dart';
import '../orders_application_helpers.dart';
import '../order_visibility.dart';
import '../order_validation_result.dart';
import '../unit_type_helpers.dart';
import 'stateful_validator.dart';
import 'work_order_cost_calculator.dart';
import 'work_order_target_prechecks.dart';

/// Nullable result means “continue”; first non-null result short-circuits the
/// pipeline (Refs #2391 AC9).
typedef _WorkOrderValidationGate = OrderValidationResult? Function();

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
    this.civilianDraftMoveUnitIds = const <String>{},
    this.diplomaticOrders = const <DiplomaticOrder>[],
    this.topology,
    this.factionMembership,
  });

  final Game game;
  final Player player;
  final String playerId;
  final PlayerView view;
  final Map<String, Unit> unitsById;
  final Set<String> devExclusiveTiles;
  final Map<String, TileMapResult>? tileMapByRegion;
  final Set<String> civilianDraftMoveUnitIds;
  final List<DiplomaticOrder> diplomaticOrders;
  final MapTopology? topology;

  /// When set, avoids repeated linear faction classification in tile occupancy
  /// checks (Refs #2394).
  final DiplomacyFactionMembership? factionMembership;
}

class WorkOrderValidator extends StatefulValidator {
  final WorkOrderValidationContext _context;

  final Set<String> _seenUnitIds;

  WorkOrderValidator({
    required WorkOrderValidationContext context,
    required Stockpile stockpile,
    required int treasury,
    Set<String> initialSeenUnitIds = const <String>{},
  }) : _context = context,
       _seenUnitIds = {...initialSeenUnitIds},
       super(
         stockpileState: stockpile,
         treasuryState: treasury,
         workerPoolState: context.player.workerPool,
       );

  Stockpile get stockpile => stockpileState;
  int get treasury => treasuryState;

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
        final targetProvinceId = Unit.provinceIdFromTileKey(o.targetTileKey);
        final province = targetProvinceId != null
            ? _context.game.worldState.tryGetProvince(targetProvinceId)
            : null;
        final ownerId = province?.ownerId;

        final gates = <_WorkOrderValidationGate>[
          () => _validateOwnedUnseenUnit(o, unit),
          () {
            final type = unit!.type;
            return _validateWorkTargetAndTile(o, type);
          },
          () => _runTargetPrecheck(
            o: o,
            targetProvinceId: targetProvinceId,
            ownerId: ownerId,
            type: unit!.type,
          ),
          () => _validateForeignProvinceWork(
            o: o,
            type: unit!.type,
            ownerId: ownerId,
          ),
          () => _validateDevExclusiveWorkTarget(o, unit!.type),
          () => _validateMaterialAndTechRules(o, province?.fortLevel ?? 0),
          () {
            if (!workOrderVisibilityOk(
              _context.view,
              unit!,
              o.target,
              targetTileKey: o.targetTileKey,
              worldState: _context.game.worldState,
            )) {
              return OrderValidationResult.rejected(
                'Province or tile not visible for this work',
              );
            }
            return null;
          },
          () {
            if (!civilianMayOccupyLandTileKey(
              game: _context.game,
              playerId: _context.playerId,
              unitType: unit!.type,
              destinationTileKey: o.targetTileKey,
              factionMembership: _context.factionMembership,
            )) {
              return OrderValidationResult.rejected(
                'Unit cannot occupy target tile',
              );
            }
            return null;
          },
          () => _validateProspectTarget(o),
        ];

        for (final gate in gates) {
          final hit = gate();
          if (hit != null) {
            return hit;
          }
        }

        final type = unit!.type;
        if (isDevExclusiveUnitType(type) &&
            isDevExclusiveWorkTarget(o.target)) {
          _context.devExclusiveTiles.add(o.targetTileKey);
        }

        _applyProjectedWorkCost(o);

        return OrderValidationResult.accepted();
      },
    );
  }

  OrderValidationResult? _validateOwnedUnseenUnit(WorkOrder o, Unit? unit) {
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
    if (_context.civilianDraftMoveUnitIds.contains(o.unitId)) {
      return OrderValidationResult.rejected(kReasonCivilianMoveXorWorkOrder);
    }
    return null;
  }

  OrderValidationResult? _validateWorkTargetAndTile(WorkOrder o, String type) {
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
    return null;
  }

  OrderValidationResult? _runTargetPrecheck({
    required WorkOrder o,
    required String? targetProvinceId,
    required String? ownerId,
    required String type,
  }) {
    final preCtx = WorkOrderTargetPrecheckContext(
      game: _context.game,
      player: _context.player,
      playerId: _context.playerId,
      treasury: treasuryState,
      civilianEmbassyWorkAllowed: _civilianWorkAllowedInMinorTribeProvince,
      factionMembership: _context.factionMembership,
    );
    return runWorkOrderTargetPrecheck(
      preCtx,
      o,
      targetProvinceId,
      ownerId,
      type,
    );
  }

  OrderValidationResult? _validateForeignProvinceWork({
    required WorkOrder o,
    required String type,
    required String? ownerId,
  }) {
    if (isExplorerUnit(type) ||
        kWorkTargetsSkippingDefaultForeignProvinceCheck.contains(o.target)) {
      return null;
    }
    final controlled = isTileControlledByPlayer(
      _context.game,
      _context.playerId,
      o.targetTileKey,
    );
    final embassyWork = _civilianWorkAllowedInMinorTribeProvince(type, ownerId);
    if (controlled || embassyWork) {
      return null;
    }
    return OrderValidationResult.rejected('Cannot work in foreign province');
  }

  OrderValidationResult? _validateDevExclusiveWorkTarget(
    WorkOrder o,
    String type,
  ) {
    if (!isDevExclusiveUnitType(type) || !isDevExclusiveWorkTarget(o.target)) {
      return null;
    }
    if (!_context.devExclusiveTiles.contains(o.targetTileKey)) {
      return null;
    }
    return OrderValidationResult.rejected(
      'Tile already has development or purchase work for this player',
    );
  }

  OrderValidationResult? _validateMaterialAndTechRules(
    WorkOrder o,
    int fortLevel,
  ) {
    if (_skipsMaterialAndTechValidation(o.target)) return null;
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

  bool _skipsMaterialAndTechValidation(String target) =>
      target == kWorkTargetStealTech ||
      target == kWorkTargetCounterSpy ||
      target == kWorkTargetPurchaseLand;

  int _improvementLevelForCost(WorkOrder o) =>
      o.target == kWorkTargetBuildImprovement
      ? _context.game.worldState.tileState.improvementLevel(o.targetTileKey)
      : 0;

  OrderValidationResult? _validateRoadFortRailTech(
    WorkOrder o,
    int fortLevel,
    int roadLevel,
  ) {
    final roadResult = _validateRoadTech(o.target, roadLevel);
    if (roadResult != null) return roadResult;
    final fortResult = _validateFortTech(o.target, fortLevel);
    if (fortResult != null) return fortResult;
    return _validateRailTech(o, roadLevel);
  }

  OrderValidationResult? _validateRoadTech(String target, int roadLevel) {
    if (target != kWorkTargetBuildRoad || roadLevel < 1) return null;
    final hasRoadConstruction =
        _context.player.techUnlocked?[kTechIdRoadConstruction] == true;
    if (hasRoadConstruction) return null;
    return OrderValidationResult.rejected(
      'Road Construction tech required for transport level 2',
    );
  }

  OrderValidationResult? _validateFortTech(String target, int fortLevel) {
    if (target != kWorkTargetBuildFort) return null;
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
    return null;
  }

  OrderValidationResult? _validateRailTech(WorkOrder o, int roadLevel) {
    if (o.target != kWorkTargetBuildRail) return null;
    final terrain = terrainTypeForTileKey(
      _context.tileMapByRegion,
      o.targetTileKey,
    );
    final reason = rejectionReasonForBuildRailOrder(
      techUnlocked: _context.player.techUnlocked,
      roadLevel: roadLevel,
      terrain: terrain,
    );
    if (reason == null) return null;
    return OrderValidationResult.rejected(reason);
  }

  OrderValidationResult? _validateWorkMaterialCosts(
    WorkOrder o, {
    required int improvementLevel,
    required int fortLevel,
    required int roadLevel,
  }) {
    final costMap = _workCostMap(
      o.target,
      o.targetTileKey,
      improvementLevel: improvementLevel,
      fortLevel: fortLevel,
      roadLevel: roadLevel,
    );
    if (costMap == null) return null;
    if (_hasInsufficientStockpileForCost(costMap)) {
      return OrderValidationResult.rejected(
        'Insufficient materials for work order',
      );
    }
    return null;
  }

  Map<String, int>? _workCostMap(
    String target,
    String tileKey, {
    required int improvementLevel,
    required int fortLevel,
    required int roadLevel,
  }) => WorkOrderCostCalculator(_context.game, playerId: _context.playerId)
      .calculateCost(
        target,
        tileKey,
        improvementLevel: improvementLevel,
        fortLevel: fortLevel,
        roadLevel: roadLevel,
      );

  bool _hasInsufficientStockpileForCost(Map<String, int> costMap) =>
      !ProjectedCostEngine.canAffordWorkMaterialCost(stockpileState, costMap);

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
    if (_applyProjectedPurchaseLandCost(o)) return;
    if (_skipsProjectedCost(o.target)) return;
    final costMap =
        WorkOrderCostCalculator(
          _context.game,
          playerId: _context.playerId,
        ).calculateCost(
          o.target,
          o.targetTileKey,
          improvementLevel: _improvementLevelForCost(o),
        );
    if (costMap == null) return;
    _applyProjectedCostMap(costMap);
  }

  bool _applyProjectedPurchaseLandCost(WorkOrder o) {
    if (o.target != kWorkTargetPurchaseLand) return false;
    // Treasury is validated in precheck and charged only on work completion
    // (SPEC/program/orders.md); do not deduct here.
    return true;
  }

  bool _skipsProjectedCost(String target) =>
      target == kWorkTargetStealTech || target == kWorkTargetCounterSpy;

  void _applyProjectedCostMap(Map<String, int> costMap) {
    if (!ProjectedCostEngine.canAffordWorkMaterialCost(
      stockpileState,
      costMap,
    )) {
      return;
    }
    stockpileState = ProjectedCostEngine.deductWorkMaterialCost(
      stockpileState,
      costMap,
    );
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
    if (!isMinorOrTribe(
      _context.game,
      provinceOwnerId,
      factionMembership: _context.factionMembership,
    )) {
      return false;
    }
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
