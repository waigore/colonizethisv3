import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../order_work_constants.dart';
import '../order_validation_result.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import '../bundled_civilian_work_order.dart';
import '../diplomatic_access_helpers.dart';
import '../order_visibility.dart';
import '../unit_type_helpers.dart';
import 'stateful_validator.dart';
import 'work_order_target_prechecks.dart';
import 'work_order_validator_material.dart';

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

  final WorkOrderValidationContext _context;
  final Set<String> _seenUnitIds;

  /// Package-visible for [WorkOrderValidatorMaterial] extension (Refs #4246).
  WorkOrderValidationContext get workOrderContext => _context;

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
          () => validateMaterialAndTechRules(o, province?.fortLevel ?? 0),
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
          () => validateProspectTarget(o),
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

        applyProjectedWorkCost(o);

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
      devExclusiveTiles: _context.devExclusiveTiles,
      civilianEmbassyWorkAllowed: (unitType, provinceOwnerId) =>
          civilianEmbassyWorkAllowedInMinorTribeProvince(
            game: _context.game,
            playerId: _context.playerId,
            player: _context.player,
            unitType: unitType,
            provinceOwnerId: provinceOwnerId,
            factionMembership: _context.factionMembership,
          ),
      factionMembership: _context.factionMembership,
      tileMapByRegion: _context.tileMapByRegion,
    );
    return runWorkOrderTargetPrecheck(
      preCtx,
      o,
      targetProvinceId,
      ownerId,
      type,
    );
  }
}
