import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../../world/player_view.dart';
import '../../world/province_lookup.dart';
import '../../world/tile_control.dart';
import '../order_visibility.dart';
import '../order_validation_result.dart';
import 'work_order_cost_calculator.dart';

bool isDevExclusiveUnitType(String type) =>
    type == 'Builder' || type == 'Engineer' || type == 'Merchant';

/// Validates work orders for a single player in submission order.
/// Mutates internal economy state (stockpile, treasury) and [devExclusiveTiles]
/// when an order is accepted. SPEC/program/orders.md § Work orders.
class WorkOrderValidator {
  final Game _game;
  final Player _player;
  final String _playerId;
  final PlayerView _view;
  final Map<String, Unit> _unitsById;
  final Set<String> _devExclusiveTiles;

  Stockpile _stockpile;
  int _treasury;

  WorkOrderValidator({
    required Game game,
    required Player player,
    required String playerId,
    required PlayerView view,
    required Map<String, Unit> unitsById,
    required Set<String> devExclusiveTiles,
    required Stockpile stockpile,
    required int treasury,
  })  : _game = game,
        _player = player,
        _playerId = playerId,
        _view = view,
        _unitsById = unitsById,
        _devExclusiveTiles = devExclusiveTiles,
        _stockpile = stockpile,
        _treasury = treasury;

  Stockpile get stockpile => _stockpile;
  int get treasury => _treasury;

  static bool _isDevExclusiveTarget(String target) =>
      target == 'build_improvement' ||
      target == 'upgrade_town' ||
      target == 'build_road' ||
      target == 'build_port' ||
      target == 'build_fort' ||
      target == 'purchase_land';

  /// Validates one [WorkOrder]. When accepted, deducts cost from internal
  /// stockpile/treasury and may add to [devExclusiveTiles]. Caller should sync
  /// stockpile/treasury back after the work loop.
  OrderValidationResult validate(
    WorkOrder o, {
    required bool previousRejected,
  }) {
    if (previousRejected) {
      return previousInvalidOrderResult;
    }

    final unit = _unitsById[o.unitId];
    if (unit == null || unit.ownerId != _playerId) {
      return const OrderValidationResult(
        status: OrderValidationStatus.rejected,
        reason: 'Unit not found',
      );
    }
    if (unit.currentWork != null) {
      return const OrderValidationResult(
        status: OrderValidationStatus.rejected,
        reason: 'Unit already has a work order; cancel first',
      );
    }
    final type = unit.type;
    if (!isWorkOrderTargetAllowedForUnitType(type, o.target)) {
      return const OrderValidationResult(
        status: OrderValidationStatus.rejected,
        reason: 'Invalid work target for unit type',
      );
    }
    if (o.targetTileKey.isEmpty) {
      return const OrderValidationResult(
        status: OrderValidationStatus.rejected,
        reason: 'Work order requires a target tile',
      );
    }

    final targetProvinceId = Unit.provinceIdFromTileKey(o.targetTileKey);
    final province = targetProvinceId != null
        ? tryGetProvince(_game.worldState, targetProvinceId)
        : null;
    final ownerId = province?.ownerId;

    if (o.target == 'steal_tech') {
      if (targetProvinceId == null) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Invalid target for steal_tech',
        );
      }
      final otherPlayer = _game.players
          .where((p) =>
              p.id != _playerId && p.capitalProvinceId == targetProvinceId)
          .firstOrNull;
      if (otherPlayer == null) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason:
              'steal_tech target must be another Great Power capital province',
        );
      }
      final ourTech = _player.techUnlocked ?? {};
      final theirTech = otherPlayer.techUnlocked ?? {};
      final hasTechWeLack = theirTech.entries
          .any((e) => e.value == true && ourTech[e.key] != true);
      if (!hasTechWeLack) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Target has no technology you lack',
        );
      }
    } else if (o.target == 'counter_spy') {
      if (ownerId != _playerId) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'counter_spy target must be your own province',
        );
      }
    } else if (o.target == 'purchase_land') {
      if (ownerId == null || ownerId == _playerId) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'purchase_land target must be a Minor or Tribe province',
        );
      }
      final isMinor = _game.minorNations.any((m) => m.id == ownerId);
      final isTribe = _game.tribes.any((t) => t.id == ownerId);
      if (!isMinor && !isTribe) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'purchase_land target must be a Minor or Tribe province',
        );
      }
      final rel = _game.diplomacyRelations
          .where((r) =>
              (r.factionId1 == _playerId && r.factionId2 == ownerId) ||
              (r.factionId2 == _playerId && r.factionId1 == ownerId))
          .firstOrNull;
      if (rel != null && rel.atWar) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Cannot purchase land: at war with that faction',
        );
      }
      final overture = _game.overtureStates
          .where((ov) => ov.gpId == _playerId && ov.targetId == ownerId)
          .firstOrNull;
      if (overture == null || !overture.hasEmbassy) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason:
              'Cannot purchase land: embassy required with that Minor/Tribe',
        );
      }
      final resourceId = _game.worldState.resourceByTileKey[o.targetTileKey];
      if (resourceId == null || resourceId.isEmpty) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Tile has no resource',
        );
      }
      if (kMineralResourceIds.contains(resourceId)) {
        final prospected =
            _game.worldState.playerProspectedTiles[_playerId] ?? const <String>{};
        if (!prospected.contains(o.targetTileKey)) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Mineral tile must be prospected first',
          );
        }
      }
      final cost = purchaseLandCost(resourceId);
      if (_treasury < cost) {
        return OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Insufficient treasury for purchase_land (need $cost)',
        );
      }
      final existingBuyer =
          _game.worldState.purchasedTilesByTileKey[o.targetTileKey];
      if (existingBuyer != null) {
        return OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: existingBuyer == _playerId
              ? 'You already own this tile'
              : 'Tile already purchased by another power',
        );
      }
    } else if (o.target == 'build_improvement') {
      final controlled =
          isTileControlledByPlayer(_game, _playerId, o.targetTileKey);
      if (!controlled) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Cannot build improvement in foreign or uncontrolled province',
        );
      }
      final resourceId = _game.worldState.resourceByTileKey[o.targetTileKey];
      if (resourceId == null || resourceId.isEmpty) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason:
              'Tile has no resource; build_improvement requires a resource on the tile',
        );
      }
      final currentLevel =
          _game.worldState.tileState.improvementLevel(o.targetTileKey);
      if (currentLevel >= 4) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Improvement level already at maximum (4)',
        );
      }
      final techCap = extractionCapForUnlocked(_player.techUnlocked);
      if (currentLevel + 1 > techCap) {
        return OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason:
              'Insufficient tech to build next improvement level (cap $techCap)',
        );
      }
    } else if (!isExplorerUnit(type)) {
      final controlled =
          isTileControlledByPlayer(_game, _playerId, o.targetTileKey);
      if (!controlled) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Cannot work in foreign province',
        );
      }
    }

    if (isDevExclusiveUnitType(type) &&
        _isDevExclusiveTarget(o.target) &&
        _devExclusiveTiles.contains(o.targetTileKey)) {
      return const OrderValidationResult(
        status: OrderValidationStatus.rejected,
        reason:
            'Tile already has development or purchase work for this player',
      );
    }

    if (o.target != 'steal_tech' &&
        o.target != 'counter_spy' &&
        o.target != 'purchase_land') {
      final improvementLevel = o.target == 'build_improvement'
          ? _game.worldState.tileState.improvementLevel(o.targetTileKey)
          : 0;
      final fortLevel = province?.fortLevel ?? 0;
      final roadLevel = _game.worldState.tileState.roadLevel(o.targetTileKey);
      if (o.target == 'build_road' && roadLevel >= 1) {
        final hasRoadConstruction =
            _player.techUnlocked?['road_construction'] == true;
        if (!hasRoadConstruction) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Road Construction tech required for transport level 2',
          );
        }
      }
      if (o.target == 'build_fort') {
        if (fortLevel == 1 &&
            _player.techUnlocked?['mine_engineering'] != true) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Mine Engineering tech required for fort level 2',
          );
        }
        if (fortLevel == 2 &&
            _player.techUnlocked?['modern_forts'] != true) {
          return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Modern Forts tech required for fort level 3',
          );
        }
      }
      final costMap = WorkOrderCostCalculator(_game).calculateCost(
        o.target,
        o.targetTileKey,
        improvementLevel: improvementLevel,
        fortLevel: fortLevel,
        roadLevel: roadLevel,
      );
      if (costMap != null) {
        for (final entry in costMap.entries) {
          if (_stockpile.quantityOf(entry.key) < entry.value) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Insufficient materials for work order',
            );
          }
        }
      }
    }

    if (!workOrderVisibilityOk(_view, unit, o.target, o.targetTileKey)) {
      return const OrderValidationResult(
        status: OrderValidationStatus.rejected,
        reason: 'Province or tile not visible for this work',
      );
    }

    if (isDevExclusiveUnitType(type) && _isDevExclusiveTarget(o.target)) {
      _devExclusiveTiles.add(o.targetTileKey);
    }

    // Apply projected cost so subsequent work orders see updated state.
    if (o.target == 'purchase_land') {
      final resourceId = _game.worldState.resourceByTileKey[o.targetTileKey];
      if (resourceId != null && resourceId.isNotEmpty) {
        final cost = purchaseLandCost(resourceId);
        _treasury -= cost;
      }
    } else if (o.target != 'steal_tech' && o.target != 'counter_spy') {
      final improvementLevel = o.target == 'build_improvement'
          ? _game.worldState.tileState.improvementLevel(o.targetTileKey)
          : 0;
      final costMap = WorkOrderCostCalculator(_game).calculateCost(
        o.target,
        o.targetTileKey,
        improvementLevel: improvementLevel,
      );
      if (costMap != null) {
        for (final entry in costMap.entries) {
          if (_stockpile.quantityOf(entry.key) >= entry.value) {
            _stockpile = _stockpile.applyDelta(entry.key, -entry.value);
          }
        }
      }
    }

    return const OrderValidationResult(
      status: OrderValidationStatus.accepted,
    );
  }
}
