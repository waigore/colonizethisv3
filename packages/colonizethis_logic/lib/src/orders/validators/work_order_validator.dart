import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../../diplomacy/diplomacy_resolver.dart';
import '../../world/player_view.dart';
import '../../world/province_lookup.dart';
import '../../world/tile_control.dart';
import '../order_visibility.dart';
import '../order_validation_result.dart';
import '../unit_type_helpers.dart';
import 'work_order_cost_calculator.dart';

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
        final unit = _unitsById[o.unitId];
        if (unit == null || unit.ownerId != _playerId) {
          return OrderValidationResult.rejected('Unit not found');
        }
        if (unit.currentWork != null) {
          return OrderValidationResult.rejected('Unit already has a work order; cancel first');
        }
        final type = unit.type;
        if (!isWorkOrderTargetAllowedForUnitType(type, o.target)) {
          return OrderValidationResult.rejected('Invalid work target for unit type');
        }
        if (o.targetTileKey.isEmpty) {
          return OrderValidationResult.rejected('Work order requires a target tile');
        }

        final targetProvinceId = Unit.provinceIdFromTileKey(o.targetTileKey);
        final province = targetProvinceId != null
            ? tryGetProvince(_game.worldState, targetProvinceId)
            : null;
        final ownerId = province?.ownerId;

        if (o.target == 'steal_tech') {
          if (targetProvinceId == null) {
            return OrderValidationResult.rejected('Invalid target for steal_tech');
          }
          final otherPlayer = _game.players
              .where((p) =>
                  p.id != _playerId && p.capitalProvinceId == targetProvinceId)
              .firstOrNull;
          if (otherPlayer == null) {
            return OrderValidationResult.rejected(
                'steal_tech target must be another Great Power capital province');
          }
          final ourTech = _player.techUnlocked ?? {};
          final theirTech = otherPlayer.techUnlocked ?? {};
          final hasTechWeLack = theirTech.entries
              .any((e) => e.value == true && ourTech[e.key] != true);
          if (!hasTechWeLack) {
            return OrderValidationResult.rejected('Target has no technology you lack');
          }
        } else if (o.target == 'counter_spy') {
          if (ownerId != _playerId) {
            return OrderValidationResult.rejected('counter_spy target must be your own province');
          }
        } else if (o.target == 'purchase_land') {
          if (ownerId == null || ownerId == _playerId) {
            return OrderValidationResult.rejected(
                'purchase_land target must be a Minor or Tribe province');
          }
          if (!isMinorOrTribe(_game, ownerId)) {
            return OrderValidationResult.rejected(
                'purchase_land target must be a Minor or Tribe province');
          }
          final rel = getRelation(_game, _playerId, ownerId);
          if (rel?.atWar == true) {
            return OrderValidationResult.rejected('Cannot purchase land: at war with that faction');
          }
          final overture = getOverture(_game, _playerId, ownerId);
          if (overture == null || !overture.hasEmbassy) {
            return OrderValidationResult.rejected(
                'Cannot purchase land: embassy required with that Minor/Tribe');
          }
          final resourceId = _game.worldState.resourceByTileKey[o.targetTileKey];
          if (resourceId == null || resourceId.isEmpty) {
            return OrderValidationResult.rejected('Tile has no resource');
          }
          if (kMineralResourceIds.contains(resourceId)) {
            final prospected =
                _game.worldState.playerProspectedTiles[_playerId] ?? const <String>{};
            if (!prospected.contains(o.targetTileKey)) {
              return OrderValidationResult.rejected('Mineral tile must be prospected first');
            }
          }
          final cost = purchaseLandCost(resourceId);
          if (_treasury < cost) {
            return OrderValidationResult.rejected(
                'Insufficient treasury for purchase_land (need $cost)');
          }
          final existingBuyer =
              _game.worldState.purchasedTilesByTileKey[o.targetTileKey];
          if (existingBuyer != null) {
            return OrderValidationResult.rejected(existingBuyer == _playerId
                ? 'You already own this tile'
                : 'Tile already purchased by another power');
          }
        } else if (o.target == 'build_improvement') {
          final controlled =
              isTileControlledByPlayer(_game, _playerId, o.targetTileKey);
          if (!controlled) {
            return OrderValidationResult.rejected(
                'Cannot build improvement in foreign or uncontrolled province');
          }
          final resourceId = _game.worldState.resourceByTileKey[o.targetTileKey];
          if (resourceId == null || resourceId.isEmpty) {
            return OrderValidationResult.rejected(
                'Tile has no resource; build_improvement requires a resource on the tile');
          }
          final currentLevel =
              _game.worldState.tileState.improvementLevel(o.targetTileKey);
          if (currentLevel >= 4) {
            return OrderValidationResult.rejected('Improvement level already at maximum (4)');
          }
          final techCap = extractionCapForUnlocked(_player.techUnlocked);
          if (currentLevel + 1 > techCap) {
            return OrderValidationResult.rejected(
                'Insufficient tech to build next improvement level (cap $techCap)');
          }
        } else if (!isExplorerUnit(type)) {
          final controlled =
              isTileControlledByPlayer(_game, _playerId, o.targetTileKey);
          if (!controlled) {
            return OrderValidationResult.rejected('Cannot work in foreign province');
          }
        }

        if (isDevExclusiveUnitType(type) &&
            isDevExclusiveWorkTarget(o.target) &&
            _devExclusiveTiles.contains(o.targetTileKey)) {
          return OrderValidationResult.rejected(
              'Tile already has development or purchase work for this player');
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
              return OrderValidationResult.rejected(
                  'Road Construction tech required for transport level 2');
            }
          }
          if (o.target == 'build_fort') {
            if (fortLevel == 1 &&
                _player.techUnlocked?['mine_engineering'] != true) {
              return OrderValidationResult.rejected(
                  'Mine Engineering tech required for fort level 2');
            }
            if (fortLevel == 2 &&
                _player.techUnlocked?['modern_forts'] != true) {
              return OrderValidationResult.rejected('Modern Forts tech required for fort level 3');
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
                return OrderValidationResult.rejected('Insufficient materials for work order');
              }
            }
          }
        }

        if (!workOrderVisibilityOk(_view, unit, o.target, o.targetTileKey)) {
          return OrderValidationResult.rejected('Province or tile not visible for this work');
        }

        if (isDevExclusiveUnitType(type) && isDevExclusiveWorkTarget(o.target)) {
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

        return OrderValidationResult.accepted();
      },
    );
  }
}
